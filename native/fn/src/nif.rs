// Licensed to the Apache Software Foundation (ASF) under one
// or more contributor license agreements.  See the NOTICE file
// distributed with this work for additional information
// regarding copyright ownership.  The ASF licenses this file
// to you under the Apache License, Version 2.0 (the
// "License"); you may not use this file except in compliance
// with the License.  You may obtain a copy of the License at
//
//   http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing,
// software distributed under the License is distributed on an
// "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
// KIND, either express or implied.  See the License for the
// specific language governing permissions and limitations
// under the License.
//

use crate::{
    atoms::{error, ok},
    cleanup_container, connect_to_docker, container_logs, get_image, setup_container,
    wait_container,
};
use bollard::container::StartContainerOptions;
use futures_util::TryFutureExt;
use once_cell::sync::Lazy;
use rustler::{Encoder, Env, NifStruct, OwnedEnv};
use std::{env, path::Path, thread};
use tokio::runtime::{Builder, Runtime};

static TOKIO: Lazy<Runtime> = Lazy::new(|| {
    Builder::new_current_thread()
        .enable_all()
        .build()
        .expect("Failed to start tokio runtime")
});

#[derive(NifStruct)]
#[module = "Worker.Function"]
struct Function {
    name: String,
    image: String,
    archive: String,
    main_file: String,
}

#[rustler::nif]
fn prepare_container(env: Env, function: Function, container_name: String) {
    let pid = env.pid();
    let project_path = Path::new(env!("CARGO_MANIFEST_DIR"));

    let tar_file = project_path.join(function.archive).display().to_string();

    thread::spawn(move || {
        let mut thread_env = OwnedEnv::new();
        let docker = connect_to_docker("/run/user/1001/docker.sock")
            .expect("Failed to connect to docker socket");
        let f = get_image(&docker, "node:lts-alpine").and_then(|_| {
            setup_container(
                &docker,
                &container_name,
                &(function.image),
                &(function.main_file),
                &tar_file,
            )
        });

        let result = TOKIO.block_on(f);

        match result {
            Ok(()) => thread_env.send_and_clear(&pid, |env| ok().encode(env)),
            Err(e) => thread_env.send_and_clear(&pid, |env| (error(), e.to_string()).encode(env)),
        }
    });
}

#[rustler::nif]
fn run_function(env: Env, container_name: String) {
    let pid = env.pid();
    // let container_name = "funless-node-container";

    thread::spawn(move || {
        let mut thread_env = OwnedEnv::new();
        let docker = connect_to_docker("/run/user/1001/docker.sock")
            .expect("Failed to connect to docker socket");

        let f = docker
            .start_container(&container_name, None::<StartContainerOptions<String>>)
            .and_then(|_| wait_container(&docker, &container_name))
            .and_then(|_| container_logs(&docker, &container_name));

        let result = TOKIO.block_on(f);

        match result {
            Ok(v) => {
                let logs = v.iter().map(|l| l.to_string()).collect::<Vec<String>>();
                thread_env.send_and_clear(&pid, |env| (ok(), logs).encode(env))
            }
            Err(e) => thread_env.send_and_clear(&pid, |env| (error(), e.to_string()).encode(env)),
        };
    });
}

#[rustler::nif]
fn cleanup(env: Env, container_name: String) {
    let pid = env.pid();
    // let container_name = "funless-node-container";

    thread::spawn(move || {
        let mut thread_env = OwnedEnv::new();
        let docker = connect_to_docker("/run/user/1001/docker.sock")
            .expect("Failed to connect to docker socket");

        let result = TOKIO.block_on(cleanup_container(&docker, &container_name));

        match result {
            Ok(()) => thread_env.send_and_clear(&pid, |env| ok().encode(env)),
            Err(e) => thread_env.send_and_clear(&pid, |env| (error(), e.to_string()).encode(env)),
        }
    });
}

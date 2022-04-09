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
use bollard::{
    container::{LogOutput, StartContainerOptions},
    errors::Error,
};
use bytes::Bytes;
use r#fn::{
    cleanup_container, connect_to_docker, container_logs, get_image, setup_container,
    wait_container,
};
use std::{env, path::Path};

#[tokio::test]
async fn test_hello() -> Result<(), Error> {
    let project_path = Path::new(env!("CARGO_MANIFEST_DIR"));

    let docker_path: String =
        env::var("FUNLESS_DOCKER_PATH").unwrap_or("/var/run/docker.sock".to_string());
    let container_name = "funless-node-container";
    let image_name = "node:lts-alpine";
    let tar_file = project_path.join("js/hello.tar.gz").display().to_string();
    let main_file = "/opt/index.js";

    // 1. Connect to Docker
    let docker = connect_to_docker(docker_path.as_str())?;

    // 2. Get Image (Pull if not present)
    get_image(&docker, image_name).await?;

    // 3. Prepare Container with custom cmd
    setup_container(&docker, &container_name, &image_name, &main_file, &tar_file).await?;

    // 4. Start Container
    docker
        .start_container(container_name, None::<StartContainerOptions<String>>)
        .await?;

    // 5. Wait for container to run
    wait_container(&docker, &container_name).await?;

    // 6.  Retrieve response
    let logs = container_logs(&docker, &container_name).await?;

    let hello_output = Bytes::from_static(b"hello world\n");

    assert!(
        matches!(&logs[0],
            LogOutput::StdOut {
                message: msg
            } if msg == &hello_output),
        "Check container logs content"
    );

    // 7.  Cleanup
    cleanup_container(&docker, &container_name).await?;

    Ok(())
}

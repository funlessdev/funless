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

use std::fs::File;
use std::io::Read;

use bollard::errors::Error;
use bollard::image::CreateImageOptions;
use futures_util::stream::StreamExt;

use bollard::container::{
    Config, CreateContainerOptions, LogOutput, LogsOptions, RemoveContainerOptions,
    StartContainerOptions, UploadToContainerOptions, WaitContainerOptions,
};
use bollard::{Docker, API_DEFAULT_VERSION};

pub fn connect_to_docker(docker_path: &str) -> Result<Docker, Error> {
    Docker::connect_with_socket(docker_path, 10, API_DEFAULT_VERSION)
}

pub async fn get_image(docker: &Docker, image_name: &str) -> Result<(), Error> {
    let image = &mut docker.create_image(
        Some(CreateImageOptions {
            from_image: image_name,
            ..Default::default()
        }),
        None,
        None,
    );

    while let Some(Ok(l)) = image.next().await {
        println!(
            "{:?} {:?}",
            l.status.unwrap_or("".to_string()),
            l.progress.unwrap_or("".to_string())
        );
    }

    Ok(())
}

pub async fn setup_container(
    docker: &Docker,
    container_name: &str,
    image_name: &str,
    main_file: &str,
    tar_file: &str,
) -> Result<(), Error> {
    get_image(&docker, image_name).await?;

    let options = Some(CreateContainerOptions {
        name: container_name,
    });
    let command = format!("require('{main_file}').main()");

    let config = Config {
        image: Some(image_name),
        cmd: Some(vec!["node", "-e", command.as_str()]),
        ..Default::default()
    };

    let _container_response = docker.create_container(options, config).await?;

    let upload_options = Some(UploadToContainerOptions {
        path: "/opt",
        ..Default::default()
    });

    println!("Opening file {:?}", tar_file);
    let mut file = File::open(tar_file)?;
    println!("File opened");

    let mut tar_body = Vec::new();
    file.read_to_end(&mut tar_body)?;

    docker
        .upload_to_container(container_name, upload_options, tar_body.into())
        .await?;

    docker
        .start_container(container_name, None::<StartContainerOptions<String>>)
        .await?;

    Ok(())
}

pub async fn wait_container(docker: &Docker, container_name: &str) -> Result<(), Error> {
    let wait_options = Some(WaitContainerOptions {
        condition: "not-running",
    });
    let _wait_response = docker
        .wait_container(container_name, wait_options)
        .into_future()
        .await;
    Ok(())
}

pub async fn container_logs(
    docker: &Docker,
    container_name: &str,
) -> Result<Vec<LogOutput>, Error> {
    let log_options = Some(LogsOptions::<String> {
        stdout: true,
        stderr: true,
        ..Default::default()
    });
    let logs: Result<Vec<LogOutput>, Error> = docker
        .logs(container_name, log_options)
        .collect::<Vec<Result<LogOutput, Error>>>()
        .await
        .into_iter()
        .collect();

    logs
}

pub async fn cleanup_container(docker: &Docker, container_name: &str) -> Result<(), Error> {
    docker
        .remove_container(container_name, None::<RemoveContainerOptions>)
        .await?;
    Ok(())
}

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

use bollard::image::CreateImageOptions;
use futures_util::stream::StreamExt;

use bollard::container::{CreateContainerOptions, Config, StartContainerOptions, RemoveContainerOptions, LogsOptions, LogOutput, UploadToContainerOptions, WaitContainerOptions};
use bollard::{Docker, API_DEFAULT_VERSION};


async fn get_image(docker: &Docker, image_name: &str) -> Result<(), String> {
    let image = &mut docker.create_image(Some(CreateImageOptions{
        from_image: image_name,
        ..Default::default()
    }), None, None);

    while let Some(Ok(l)) = image.next().await {
        println!("{:?} {:?}", l.status.unwrap_or("".to_string()), l.progress.unwrap_or("".to_string()));
    }

    Ok(())
}

async fn setup_container(docker: &Docker, container_name: &str, image_name: &str, main_file: &str, tar_file: &str) -> Result<(), Box<dyn std::error::Error>> {

    get_image(&docker, image_name).await?;
    
    let options = Some(CreateContainerOptions {
        name: container_name
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
    let mut file = File::open(tar_file)?;
    let mut tar_body = Vec::new();
    file.read_to_end(&mut tar_body)?;

    docker.upload_to_container(container_name, upload_options, tar_body.into()).await?;

    docker.start_container(container_name, None::<StartContainerOptions<String>>).await?;

    Ok(())
}

#[tokio::main(flavor = "current_thread")]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    
    const DOCKER_PATH: &str = "/run/user/1001/docker.sock";
    const IMAGE_NAME: &str = "node:lts-alpine";
    const CONTAINER_NAME: &str = "funless-node-container";
    const TAR_FILE: &str = "./js/hello.tar.gz";
    const MAIN_FILE: &str = "/opt/index.js";

    let docker = Docker::connect_with_socket(DOCKER_PATH, 10, API_DEFAULT_VERSION)?;

    setup_container(&docker, CONTAINER_NAME, IMAGE_NAME, MAIN_FILE, TAR_FILE).await?;

    let log_options = Some(LogsOptions::<String> {
        stdout: true,
        stderr: true,
        ..Default::default()
    });
    let logs = &mut docker.logs(CONTAINER_NAME, log_options);

    let wait_options = Some(WaitContainerOptions{
        condition: "not-running"
    });
    let _wait_response = docker.wait_container(CONTAINER_NAME, wait_options).into_future().await;

    while let Some(Ok(l)) = logs.next().await {
        match l {
            LogOutput::StdOut {message: m} => println!("Logs: {:?}", m),
            LogOutput::StdErr { message: m } => eprintln!("Error: {:?}", m),
            _ => continue
        }
    }

    docker.remove_container(CONTAINER_NAME, None::<RemoveContainerOptions>).await?;
    println!("Container removed.");

    Ok(())
}

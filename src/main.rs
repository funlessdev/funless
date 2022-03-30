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

use bollard::image::CreateImageOptions;
use futures_util::stream::StreamExt;

use bollard::container::{CreateContainerOptions, Config, StartContainerOptions, RemoveContainerOptions, LogsOptions};
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

#[tokio::main(flavor = "current_thread")]
async fn main() -> Result<(), Box<dyn std::error::Error + 'static>> {
    let docker = Docker::connect_with_socket("/run/user/1001/docker.sock", 10, API_DEFAULT_VERSION)?;

    get_image(&docker, "alpine:latest").await?;

    let options = Some(CreateContainerOptions {
        name: "funless-alpine-container"
    });
    let config = Config {
        image: Some("alpine:latest"),
        cmd: Some(vec!["echo", "hello"]),
        ..Default::default()
    };
    
    let container_response = docker.create_container(options, config).await?;
    println!("Container ID: {:?}", container_response.id);
    docker.start_container("funless-alpine-container", None::<StartContainerOptions<String>>).await?;

    let log_options = Some(LogsOptions::<String> {
        stdout: true,
        ..Default::default()
    });
    let logs = &mut docker.logs("funless-alpine-container", log_options).take(1);

    while let Some(Ok(l)) = logs.next().await {
        println!("Logs: {:?}", l);
    }

    docker.remove_container("funless-alpine-container", None::<RemoveContainerOptions>).await?;
    println!("Container removed.");

    Ok(())
}

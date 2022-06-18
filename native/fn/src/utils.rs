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
use bollard::errors::Error;
use bollard::image::CreateImageOptions;
use bollard::models::NetworkSettings;
use futures_util::stream::StreamExt;

use bollard::container::{LogOutput, LogsOptions};
use bollard::{Docker, API_DEFAULT_VERSION};

pub fn connect_to_docker(docker_path: &str) -> Result<Docker, Error> {
    if docker_path.starts_with("tcp://") || docker_path.starts_with("http://") {
        Docker::connect_with_http(docker_path, 10, API_DEFAULT_VERSION)
    } else {
        Docker::connect_with_socket(docker_path, 10, API_DEFAULT_VERSION)
    }
}

pub fn select_image(image_name: &str) -> Result<&str, &str> {
    match image_name {
        "nodejs" => Ok("openwhisk/action-nodejs-v16"),
        _ => Err("No image found for the given name"),
    }
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
            l.status.unwrap_or_default(),
            l.progress.unwrap_or_default()
        );
    }

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

pub fn extract_host_port(ns: Option<NetworkSettings>, rootless: bool) -> Option<(String, String)> {
    let network_settings = ns?;
    let bridge_network = network_settings.networks?.get("bridge")?.to_owned();
    let host = if rootless {
        "localhost".to_string()
    } else {
        bridge_network.ip_address?
    };
    let ports = network_settings.ports?.get("8080/tcp")?.to_owned();
    /* TODO: should be the port associated with the 0.0.0.0 address */
    let port = if rootless {
        ports?[0].to_owned().host_port?
    } else {
        "8080".to_string()
    };
    Some((host, port))
}

#[cfg(test)]
mod tests {
    use std::collections::HashMap;

    use bollard::models::{EndpointSettings, PortBinding};

    use super::*;

    #[test]
    fn test_extract_host_port() {
        let port_number = "36719";
        let ip_address = "172.17.0.2";
        let ns = Some(NetworkSettings {
            networks: Some(HashMap::from([(
                String::from("bridge"),
                EndpointSettings {
                    ip_address: Some(String::from(ip_address)),
                    ..Default::default()
                },
            )])),
            ports: Some(HashMap::from([(
                String::from("8080/tcp"),
                Some(vec![PortBinding {
                    host_ip: Some(String::from("0.0.0.0")),
                    host_port: Some(String::from(port_number)),
                }]),
            )])),
            ..Default::default()
        });
        assert_eq!(
            Some((String::from(ip_address), String::from("8080"))),
            extract_host_port(ns.to_owned(), false),
            "extract rootful host and port"
        );
        assert_eq!(
            Some((String::from("localhost"), String::from(port_number))),
            extract_host_port(ns, true),
            "extract rootless host and port"
        );
    }
}

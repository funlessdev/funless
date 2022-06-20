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

/// Returns a Docker connection struct to the specified socket path.
///
/// Returns `None` if the path is invalid or the connection fails.
///
/// # Arguments
///
/// * `docker_path` - A string slice holding the Docker host or socket path
///
pub fn connect_to_docker(docker_path: &str) -> Result<Docker, Error> {
    if docker_path.starts_with("tcp://") || docker_path.starts_with("http://") {
        Docker::connect_with_http(docker_path, 10, API_DEFAULT_VERSION)
    } else {
        Docker::connect_with_socket(docker_path, 10, API_DEFAULT_VERSION)
    }
}

/// Returns the Docker image associated with the given string.
///
/// Returns `None` if the given string has no corresponding image.
///
/// # Arguments
///
/// * `image_name` -  A string slice holding the short name for the Docker image
pub fn select_image(image_name: &str) -> Option<&str> {
    match image_name {
        "nodejs" => Some("openwhisk/action-nodejs-v16"),
        _ => None,
    }
}

/// Wrapper for the bollard create_image function.
///
/// Returns an `Error` if something goes wrong while checking or downloading the image (e.g. an invalid image name is given).
///
/// Returns `Ok(())` if the image is downloaded correctly, or was already available.
///
/// # Arguments
///
/// * `docker` - A reference to a Docker connection, used by the create_image function
/// * `image_name` - A string slice holding the Docker image's name
///
pub async fn get_image(docker: &Docker, image_name: &str) -> Result<(), Error> {
    let image = &mut docker.create_image(
        Some(CreateImageOptions {
            from_image: image_name,
            ..Default::default()
        }),
        None,
        None,
    );

    while let Some(l) = image.next().await {
        let info = l?;
        println!(
            "{:?} {:?}",
            &info.status.unwrap_or_default(),
            &info.progress.unwrap_or_default()
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

/// Extract host and port from a `NetworkSettings` struct.
///
/// Returns `None` if some of the necessary fields are `None`.
/// Returns `(host, "8080")`, with `host` being the container internal ip address.
///
/// Should be used only in rootful mode, as the `bridge0` network interface is not created by rootless Docker, which is necessary for
/// host->guest communication using internal container IP addresses.
///
/// # Arguments
///
/// * `ns` - A `NetworkSettings` struct wrapped by an `Option`, holds a Docker container's network information
///
pub fn extract_host_port(ns: Option<NetworkSettings>) -> Option<(String, String)> {
    let network_settings = ns?;
    let networks = network_settings.networks?;
    let bridge_network = networks.get("bridge")?;
    let host = bridge_network.ip_address.clone()?;
    let port = String::from("8080");
    Some((host, port))
}

/// Extract host and port from a `NetworkSettings` struct for a rootless Docker system.
///
/// Returns `None` if some of the necessary fields are `None`.
/// Returns `("localhost", port)`, with `port` being the host port forwarded to the `8080/tcp` container port.
///
/// # Arguments
///
/// * `ns` - A `NetworkSettings` struct wrapped by an `Option`, holds a Docker container's network information
///
pub fn extract_rootless_host_port(ns: Option<NetworkSettings>) -> Option<(String, String)> {
    let network_settings = ns?;
    let host = String::from("localhost");
    let ports = network_settings.ports?;
    let bindings = ports.get("8080/tcp")?.as_ref()?;
    /* TODO: should be the port associated with the 0.0.0.0 address */
    let port = bindings[0].host_port.clone()?;
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
            extract_host_port(ns.to_owned()),
            "extract rootful host and port"
        );
        assert_eq!(
            Some((String::from("localhost"), String::from(port_number))),
            extract_rootless_host_port(ns),
            "extract rootless host and port"
        );
    }
}

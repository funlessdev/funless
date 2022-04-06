use bollard::{container::LogOutput, errors::Error};
use bytes::Bytes;
use funless_fn::{
    cleanup_container, connect_to_docker, container_logs, setup_container, wait_container,
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

    let docker = connect_to_docker(docker_path.as_str())?;

    setup_container(&docker, &container_name, &image_name, &main_file, &tar_file).await?;

    wait_container(&docker, &container_name).await?;

    let logs = container_logs(&docker, &container_name).await?;
    let hello_output = Bytes::from_static(b"hello world\n");

    assert!(
        matches!(&logs[0],
            LogOutput::StdOut {
                message: msg
            } if msg == &hello_output),
        "Check container logs content"
    );

    cleanup_container(&docker, &container_name).await?;

    Ok(())
}

use crate::{connect_to_docker, get_image, setup_container};
use futures_util::TryFutureExt;
use once_cell::sync::Lazy;
use tokio::runtime::{Builder, Runtime};

static TOKIO: Lazy<Runtime> = Lazy::new(|| {
    Builder::new_current_thread()
        .enable_all()
        .build()
        .expect("Failed to start tokio runtime")
});

#[rustler::nif]
fn prepare_container() -> i64 {
    let container_name = "funless-node-container";
    let image_name = "node:lts-alpine";
    let tar_file = "./hello.tar.gz";
    let main_file = "/opt/index.js";

    let docker = connect_to_docker("/run/user/1001/docker.sock")
        .expect("Failed to connect to docker socket");
    let f = get_image(&docker, "node:lts-alpine").and_then(|_| {
        setup_container(&docker, &container_name, &image_name, &main_file, &tar_file)
    });

    let _result = TOKIO.block_on(f);

    0
}

#[rustler::nif]
fn run_function() {}

#[rustler::nif]
fn cleanup() {}

mod atoms;
mod nif;
pub mod utils;

rustler::init!(
    "Elixir.Worker.Nif.Fn",
    [nif::prepare_container, nif::container_logs, nif::cleanup,]
);

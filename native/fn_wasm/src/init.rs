mod atoms;
mod nif;
pub mod utils;

rustler::init!(
    "Elixir.Worker.Adapters.Runtime.Wasm.Nif",
    [nif::run_function]
);

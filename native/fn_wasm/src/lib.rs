// Copyright 2022 Giuseppe De Palma, Matteo Trentin
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

use rustler::{Env, Term};

mod engine;
mod atoms;
mod nif;
pub mod utils;

pub fn load(env: Env, _: Term) -> bool {    
    engine::load(env);
    true
}

rustler::init!(
    "Elixir.Worker.Adapters.Runtime.Wasm.Nif",
    [
        nif::run_function,
        engine::init,
    ],
    load=load
);

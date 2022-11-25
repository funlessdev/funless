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

use crate::atoms;
use rustler::{
    resource::ResourceArc, types::Binary, Encoder, Env, LocalPid, NifResult, OwnedBinary, OwnedEnv,
};
use wasmtime::{Engine, Module};

use std::{sync::Mutex, thread};

use crate::engine::EngineResource;

pub struct ModuleResource {
    pub inner: Mutex<Module>,
}

#[derive(rustler::NifTuple)]
pub struct ModuleResourceResponse {
    ok: rustler::Atom,
    resource: ResourceArc<ModuleResource>,
}

impl ModuleResource {
    fn new(engine: &Engine, binary: &[u8]) -> NifResult<ModuleResourceResponse> {
        match Module::from_binary(engine, binary) {
            Ok(module) => {
                let resource = ResourceArc::new(ModuleResource {
                    inner: Mutex::new(module),
                });
                Ok(ModuleResourceResponse {
                    ok: atoms::ok(),
                    resource,
                })
            }
            Err(e) => Err(rustler::Error::Term(Box::new(format!(
                "Could not compile module: {:?}",
                e
            )))),
        }
    }
}

#[rustler::nif]
fn compile_module(env: Env, engine_resource: ResourceArc<EngineResource>, code: Binary) {
    let pid = env.pid();
    if let Some(owned_code) = code.to_owned() {
        thread::spawn(move || {
            let mut thread_env = OwnedEnv::new();
            let res = compile_in_thread(engine_resource, owned_code);
            match res {
                Ok(module_response) => {
                    thread_env.send_and_clear(&pid, |env| module_response.encode(env))
                }

                Err(rustler::Error::Term(rustler_error)) => thread_env
                    .send_and_clear(&pid, |env| {
                        (atoms::error(), rustler_error.encode(env)).encode(env)
                    }),

                _ => thread_env
                    .send_and_clear(&pid, |env| (atoms::error(), "Unknown error").encode(env)),
            }
        });
    } else {
        send_back_error(env, pid)
    }
}

fn compile_in_thread(
    engine_resource: ResourceArc<EngineResource>,
    code: OwnedBinary,
) -> NifResult<ModuleResourceResponse> {
    let binary = code.as_slice();

    let engine = &*(engine_resource.inner.lock().map_err(|e| {
        rustler::Error::Term(Box::new(format!("Could not unlock engine resource: {}", e)))
    })?);

    ModuleResource::new(engine, binary)
}

/// Sends back the `{:error, msg}` to the original Elixir process.
/// Called when `compile_module` fails to allocate an owned copy of the code.
///
/// # Arguments
///
/// * `env` - NIF parameter, passed from `run_function`
/// * `pid` - PID of the calling Elixir process
///
fn send_back_error(env: Env, pid: LocalPid) {
    let e = "Couldn't allocate code for separate thread";
    env.send(&pid, (atoms::error(), e).encode(env))
}

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
use rustler::{resource::ResourceArc, types::Binary, NifResult};
use wasmtime::{Engine, Module};

use std::sync::Mutex;

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
    // TODO: do it in another thread cause compilation (from_binary) is slow
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
fn compile_module(
    engine_resource: ResourceArc<EngineResource>,
    code: Binary,
) -> NifResult<ModuleResourceResponse> {
    let binary = code.as_slice();

    let engine: &Engine = &*(engine_resource.inner.lock().map_err(|e| {
        rustler::Error::Term(Box::new(format!("Could not unlock engine resource: {}", e)))
    })?);

    ModuleResource::new(engine, binary)
}

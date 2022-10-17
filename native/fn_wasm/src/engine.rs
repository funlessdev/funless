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
use rustler::{resource::ResourceArc, NifResult};
use std::sync::Mutex;
use wasmtime::Engine;

pub struct EngineResource {
    pub inner: Mutex<Engine>,
}

#[derive(rustler::NifTuple)]
pub struct EngineResourceResponse {
    ok: rustler::Atom,
    resource: ResourceArc<EngineResource>,
}

impl EngineResource {
    fn new() -> NifResult<EngineResourceResponse> {
        let resource = ResourceArc::new(EngineResource {
            inner: Mutex::new(Engine::default()),
        });

        Ok(EngineResourceResponse {
            ok: atoms::ok(),
            resource,
        })
    }
}

#[rustler::nif]
fn init() -> NifResult<EngineResourceResponse> {
    EngineResource::new()
}

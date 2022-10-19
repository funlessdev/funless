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

use std::thread;

use crate::{atoms, engine::EngineResource, module::ModuleResource, utils};
use rustler::{resource::ResourceArc, Encoder, Env, NifResult, OwnedEnv};
use wasi_common::pipe::ReadPipe;

/// Runs the function in the given module with the given args using the wasmtime runtime,
/// inside another thread and sends back the result to the caller.
///
/// Sends the `{:ok, result}` or `{:error, err}` response to the calling Elixir process.
///
/// The computation is moved to a different thread to avoi conflicts with the BEAM scheduler.
///
/// # Arguments
///
/// * `env` - NIF parameter, represents the calling process
/// * `engine_resource` - The reference to the wasmtime engine
/// * `module_resource` - The reference to the compiled module
/// * `args` - JSON-encoded function arguments
///
///
#[rustler::nif]
fn run_function(
    env: Env,
    engine_resource: ResourceArc<EngineResource>,
    module_resource: ResourceArc<ModuleResource>,
    args: String,
) {
    let pid = env.pid();

    thread::spawn(move || {
        let mut thread_env = OwnedEnv::new();

        let res: NifResult<(rustler::Atom, String)> =
            run_module_function(engine_resource, module_resource, args);
        match res {
            Ok((atom, output)) => thread_env.send_and_clear(&pid, |env| (atom, output).encode(env)),

            Err(rustler::Error::Term(rustler_error)) => thread_env.send_and_clear(&pid, |env| {
                (atoms::error(), rustler_error.encode(env)).encode(env)
            }),

            _ => {
                thread_env.send_and_clear(&pid, |env| (atoms::error(), "Unknown error").encode(env))
            }
        }
    });
}

fn run_module_function(
    engine_resource: ResourceArc<EngineResource>,
    module_resource: ResourceArc<ModuleResource>,
    args: String,
) -> NifResult<(rustler::Atom, String)> {
    // 1. Extract engine from resource
    let engine = &*(engine_resource.inner.lock().map_err(|e| {
        rustler::Error::Term(Box::new(format!("Could not unlock engine resource: {}", e)))
    })?);

    // 2. Extract module from resource
    let module = &*(module_resource.inner.lock().map_err(|e| {
        rustler::Error::Term(Box::new(format!("Could not unlock module resource: {}", e)))
    })?);

    // 3. Setup stdin, stdout and stderr pipes
    let (stdout, stdout_lock) = utils::make_write_pipe();
    let (stderr, stderr_lock) = utils::make_write_pipe();
    let stdin = ReadPipe::from(args);

    // 4. Create a new instance of the module function with relative store
    let (main_func_instance, mut store) =
        utils::get_main_func(engine, module, stdin, stdout, stderr).map_err(|e| {
            rustler::Error::Term(Box::new(format!(
                "Could not get function from module: {}",
                e
            )))
        })?;

    /*
    5. Run the function
    if the function completed successfully, we pass the :ok atom and the content of stdout;
    if the function's result was an error, we pass the :error atom and the content of stderr
    */
    let result = main_func_instance.call(&mut store, ());
    let (atom, lock) = match result {
        Ok(_) => (atoms::ok(), stdout_lock),
        Err(_) => (atoms::error(), stderr_lock),
    };

    // 6. Extract output
    let output = utils::extract_string(lock)?;

    Ok((atom, output))
}

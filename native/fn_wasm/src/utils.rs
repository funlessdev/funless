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

use std::{
    io::Cursor,
    string::FromUtf8Error,
    sync::{Arc, RwLock},
};

use wasi_common::{
    pipe::{ReadPipe, WritePipe},
    WasiCtx,
};
use wasmtime::{Engine, Linker, Module, Store, TypedFunc};
use wasmtime_wasi::WasiCtxBuilder;

/// Returns a couple containing a WritePipe for a buffer, and its mutex.
///
/// The WritePipe is meant to be used as stdout/stderr for a WasiCtx.
///
pub fn make_write_pipe() -> (WritePipe<Vec<u8>>, Arc<RwLock<Vec<u8>>>) {
    let buf: Vec<u8> = vec![];
    let lock = Arc::new(RwLock::new(buf));
    let pipe = WritePipe::from_shared(lock.clone());
    (pipe, lock)
}

/// Builds the necessary components and returns the main function of the given WebAssembly module.
///
/// Returns the main function as a TypedFunc<(), ()> and the Store to which the module and the context are attached.
///
/// # Arguments
///
/// * `engine` - A wasmtime::Engine
/// * `code` - A binary string containing the function's code
/// * `stdin` - A ReadPipe which will be given to the WasiCtx as stdin; should be built from the JSON string containing the function parameters
/// * `stdout`, `stderr` - WritePipes where the output and errors will be written by the module
pub fn get_main_func(
    engine: &Engine,
    code: &[u8],
    stdin: ReadPipe<Cursor<String>>,
    stdout: WritePipe<Vec<u8>>,
    stderr: WritePipe<Vec<u8>>,
) -> Result<(TypedFunc<(), ()>, Store<WasiCtx>), wasmtime_wasi::Error> {
    let module = Module::from_binary(engine, code)?;
    let wasi = WasiCtxBuilder::new()
        .stdout(Box::new(stdout))
        .stdin(Box::new(stdin))
        .stderr(Box::new(stderr))
        .build();
    let mut store = Store::new(engine, wasi);
    let mut linker = Linker::new(engine);
    wasmtime_wasi::add_to_linker(&mut linker, |s| s)?;
    linker.module(&mut store, "code", &module)?;

    let instance = linker.instantiate(&mut store, &module)?;
    let main_func = instance.get_typed_func::<(), (), _>(&mut store, "_start")?;

    Ok((main_func, store))
}

/// Extracts a string from a unicode vector guarded by a RwLock.
///
/// Returns:
///
/// - `None` if the attempt to gain read access through the lock failed
/// - `Some(FromUtf8Error)` if the underlying vector couldn't be converted to a string
/// - `Some(s)` if the underlying vector was converted to a string successfully
///
///
/// # Arguments:
///
/// - `lock` - A reader-writer lock over a Vec<u8>, encoding a unicode string
pub fn extract_string(lock: Arc<RwLock<Vec<u8>>>) -> Option<Result<String, FromUtf8Error>> {
    let mut buffer: Vec<u8> = Vec::new();
    let guard = match lock.read() {
        Ok(g) => Some(g),
        Err(_e) => None,
    };

    guard?.iter().for_each(|i| buffer.push(*i));

    Some(String::from_utf8(buffer))
}

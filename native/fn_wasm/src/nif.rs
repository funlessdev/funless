use crate::{atoms, utils};

use rustler::{types::Binary, Encoder, Env, LocalPid, OwnedBinary, OwnedEnv};
use std::thread;

use wasi_common::pipe::ReadPipe;
use wasmtime::*;

/// Runs the given function's code with the given args using the wasmtime runtime.
///
/// Sends the `{:ok, result}` or `{:error, err}` response to the calling Elixir process.
///
/// The computation is moved to a different thread to avoi conflicts with the BEAM scheduler.
///
/// # Arguments
///
/// * `env` - NIF parameter, represents the calling process
/// * `code` - Binary string holding the function's WebAssembly code
/// * `args` - JSON-encoded function arguments
///
/// Further information on the returned messages listed in `run_in_thread` and `send_back_error`.
///
#[rustler::nif]
fn run_function(env: Env, code: Binary, args: String) {
    let pid = env.pid();
    if let Some(owned_code) = code.to_owned() {
        thread::spawn(move || run_in_thread(pid, owned_code, args));
    } else {
        send_back_error(env, pid)
    }
}

/// Runs the main computation of `run_function`.
/// Instantiates the wasmtime engine and simulates stdin, stdout and stderr to be fed to the runtime.
///
/// This function is run in a separate thread and sends errors and results back to the original Elixir process.
///
/// # Arguments
///
/// * `pid` - PID of the calling Elixir process
/// * `owned_code` - WebAssembly code of the function, moved to the thread
/// * `args` - JSON-encoded function arguments, passed from `run_function`
///
/// # Messages
///
/// * `{:ok, result}` - Successful response, with `result` being a JSON-encoded string
/// * `{:error, :extract_from_utf8_error}` - When the function encouters an error converting stdout/stderr to a string
/// * `{:error, :lock_error}` - When the function encounters an error trying to gain read access to the stdout/stderr lock
/// * `{:error, {:code_error, any}}` - When the function encounters an error trying to get the main function from the WebAssembly code (this includes linking, code instantiation as a module and creation of the WasiCtx)
/// * `{:error, msg}` - When the function encounters an error during the actual execution of the given code; `msg` is the content of stderr
///  
fn run_in_thread(pid: LocalPid, owned_code: OwnedBinary, args: String) {
    let mut thread_env = OwnedEnv::new();
    let engine = Engine::default();

    let (stdout, stdout_lock) = utils::make_write_pipe();
    let (stderr, stderr_lock) = utils::make_write_pipe();
    let stdin = ReadPipe::from(args);

    match utils::get_main_func(&engine, owned_code.as_slice(), stdin, stdout, stderr) {
        Ok((main_func, mut store)) => {
            let result = main_func.call(&mut store, ());

            /*
             if the function completed successfully, we pass the :ok atom and the content of stdout;
             if the function's result was an error, we pass the :error atom and the content of stderr
            */
            let (lock, atom) = match result {
                Ok(_) => (stdout_lock, atoms::ok()),
                Err(_) => (stderr_lock, atoms::error()),
            };

            let extracted = utils::extract_string(lock);

            if let Some(output) = extracted {
                if let Ok(s) = output {
                    thread_env.send_and_clear(&pid, |env| (atom, &s).encode(env))
                } else {
                    thread_env.send_and_clear(&pid, |env| {
                        (atoms::error(), atoms::extract_from_utf8_error()).encode(env)
                    })
                }
            } else {
                thread_env.send_and_clear(&pid, |env| {
                    (atoms::error(), atoms::lock_error()).encode(env)
                })
            }
        }
        Err(error) => thread_env.send_and_clear(&pid, |env| {
            (atoms::error(), (atoms::code_error(), error.to_string())).encode(env)
        }),
    }
}

/// Sends back the `{:error, {:internal_error, msg}}` to the original Elixir process.
/// Called when `run_function` fails to allocate an owned copy of the code.
///
/// # Arguments
///
/// * `env` - NIF parameter, passed from `run_function`
/// * `pid` - PID of the calling Elixir process
///
fn send_back_error(env: Env, pid: LocalPid) {
    env.send(
        &pid,
        (
            atoms::error(),
            (
                atoms::internal_error(),
                "Couldn't allocate code for separate thread",
            ),
        )
            .encode(env),
    )
}

use crate::{atoms, utils};

use rustler::{types::Binary, Encoder, Env, LocalPid, OwnedBinary, OwnedEnv};
use std::thread;

use wasi_common::pipe::ReadPipe;
use wasmtime::*;

#[rustler::nif]
fn run_function(env: Env, code: Binary, args: String) {
    let pid = env.pid();
    if let Some(owned_code) = code.to_owned() {
        thread::spawn(move || run_in_thread(pid, owned_code, args));
    } else {
        send_back_error(env, pid)
    }
}

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

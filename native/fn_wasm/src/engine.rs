use crate::atoms::ok;
use rustler::{Env, Atom};
use rustler::resource::ResourceArc;
use wasmtime::Engine;

struct Ref(Engine);

impl Ref {
    fn new() -> ResourceArc<Ref> {
        ResourceArc::new(Ref(Engine::default()))
    }
}

pub fn load(env: Env) -> bool {
    rustler::resource!(Ref, env);
    true
}

#[rustler::nif]
fn init() -> (Atom, ResourceArc<Ref>) {
    (ok(), Ref::new())
}

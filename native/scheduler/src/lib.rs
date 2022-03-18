#[rustler::nif]
fn add(a: i64, b: i64) -> i64 {
    a + b
}

#[rustler::nif]
fn subtract(a: i64, b: i64) -> i64 {
    a - b
}

rustler::init!("Elixir.Scheduler", [add, subtract]);
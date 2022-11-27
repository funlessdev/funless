<!--
  ~ Copyright 2022 Giuseppe De Palma, Matteo Trentin
  ~
  ~ Licensed under the Apache License, Version 2.0 (the "License");
  ~ you may not use this file except in compliance with the License.
  ~ You may obtain a copy of the License at
  ~
  ~ http://www.apache.org/licenses/LICENSE-2.0
  ~
  ~ Unless required by applicable law or agreed to in writing, software
  ~ distributed under the License is distributed on an "AS IS" BASIS,
  ~ WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  ~ See the License for the specific language governing permissions and
  ~ limitations under the License.
-->

# Worker

**TODO: add description**

This is the Worker component app of the Funless (FL) platform.

The Worker is written in Elixir and makes use of Rust NIFs to run user-defined functions.

To run functions it uses the [wasmtime](https://github.com/bytecodealliance/wasmtime) WebAssembly runtime.

## Running the Worker

### Running in an interactive session

The project can be run in an interactive session by running:
```
mix deps.get
mix compile
iex -S mix
```
#### Using WebAssembly

When using the WebAssembly runtime, `fcode` must contain the binary string corresponding to a compiled WebAssembly module, preferably created using [fl-runtimes](https://github.com/funlessdev/fl-runtimes):
```
fcode = File.read!("code.wasm")
...
```
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

This is the Worker component app of the FunLess platform.

The Worker is written in Elixir and makes use of Rust NIFs to run user-defined functions.

To run functions it uses the [wasmtime](https://github.com/bytecodealliance/wasmtime) WebAssembly runtime.

It is a GenServer that receives invocation requests from the Core component.

### Running 

The project can be run in an interactive session by running:
```
mix deps.get
mix compile
iex -S mix
```

### Testing

The project can be tested by running:

```bash
mix test
```
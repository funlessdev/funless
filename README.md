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


[![documentation site](https://img.shields.io/website?label=Documentation&url=https%3A%2F%2Ffunless.dev)](https://funless.dev)
[![Tests](https://github.com/funlessdev/funless/actions/workflows/test.yml/badge.svg)](https://github.com/funlessdev/funless/actions/workflows/test.yml)
[![Docker Release](https://github.com/funlessdev/funless/actions/workflows/image-release.yml/badge.svg)](https://github.com/funlessdev/funless/packages)
![Powered by WebAssembly](https://img.shields.io/badge/powered%20by-WebAssembly-orange.svg)<br />

# FunLess
The Funless (FL) platform is a new generation, research-driven serverless platform built with with the scalability of the BEAM and the speed 
and security of WebAssembly. 

It is composed of two main parts: the Core and the Worker components.

## Core

The Core is the orchestrator of the platform. It handles http requests to upload, invoke and delete functions and resides in the apps/core folder. It is 
a Phoenix web application to expose the json REST API.

When an invocation requests arrives, the Phoenix application forwards it to the Core, which then picks one of the available Workers 
and runs the function on it.

## Worker 

The Worker is the actual executor of the functions. It makes use of Rust NIFs to run user-defined functions. It implements
a simple WebAssembly runtime using [wasmtime](https://wasmtime.dev/) which executes wasm binaries given by the Core, with 0 cold-start time.

## CLI

It is recommended to use our [Funless CLI](https://github.com/funlessdev/fl-cli) to interact with the platform, as it makes it easy to
do a local deployment and to upload, invoke and delete functions.

### Running in an interactive session

Both the Core and the Workers can be run in an interactive session by running:


First of all you need to install the dependencies:

```bash
mix deps.get
```

For the Core: 

```bash
cd apps/core && iex --name core@127.0.0.1 --cookie default_secret -S mix phx.server
```

For the Worker:

```bash
cd apps/worker && iex --name worker@127.0.0.1 --cookie default_secret -S mix
```

Now you can send post requests to `localhost:4000`. The file `core-api.yaml` contains an OpenAPI specification of the possible requests.

The cli has the `fn create/invoke/delete` commands, but if you want to use the API directly: 

- Create a new function by sending a POST request to `localhost:4000/create` with the following body:
```json
{
  "name": "hello",
  "namespace": "_",
  "code": <-the wasm file->,
}
```

You should receive as response: `{ "result": "hello" }`.

After that you can send a POST request to `localhost:4000/invoke` with the following body:
```json
{
  "namespace": "_",
  "function": "hello",
  "args": {}
}
```

If you have no connected worker to use, you will receive the error:
```json
{
  "error": "Failed to invoke function: no worker available"
}
```

Otherwise, you should receive as response the result of your function.

### Mix Release

The project can also be compiled as a release, and run like this:

For the Core: 
```
mix release core
./_build/dev/rel/core/bin/core start (or daemon to run it in the background) and stop 
```

For the Worker:
```
mix release worker
./_build/dev/rel/worker/bin/worker start (or daemon to run it in the background) and stop 
```

### Run Tests

To run the tests, you can use the following command:

```bash
mix test
```

Or, to run just the tests of the core:

```bash
mix core_test
```

Or, for the worker:

```bash
mix worker_test
```

## Contributing
Anyone is welcome to contribute to this project or any other Funless project. 

You can contribute by testing the projects, opening tickets, writing documentation, sharing new ideas for future works and, of course,
by contributing code. 

You can pick an issue or create a new one, comment on it that you will take priority and then fork the repo so you're free to work on it.
Once you feel ready open a Pull Request to send your code to us.


## License

This project is under the Apache 2.0 license.
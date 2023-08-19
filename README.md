<!--
  ~ Copyright 2023 Giuseppe De Palma, Matteo Trentin
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


[![documentation](https://img.shields.io/website?label=Documentation&url=https%3A%2F%2Ffunless.dev)](https://funless.dev)
![tests](https://github.com/funlessdev/funless/actions/workflows/core-ci.yml/badge.svg)
[![release](https://badgen.net/github/release/funlessdev/funless)](https://github.com/funlessdev/funless/releases/)
![contributors](https://badgen.net/github/contributors/funlessdev/funless) 
[![docker images](https://github.com/funlessdev/funless/actions/workflows/image-release.yml/badge.svg)](https://github.com/funlessdev/funless/packages)
![Powered by WebAssembly](https://img.shields.io/badge/powered%20by-WebAssembly-orange.svg)<br />

# FunLess
The Funless (FL) platform is a new generation, research-driven serverless platform built with with the scalability of the BEAM and the speed 
and security of WebAssembly. 

It is a research project developed in the DISI department of the University of Bologna, with the aim to provide a new 
serverless platform for the Cloud-Edge computing paradigm.

It is still in an experimental state and not ready for production use yet, but it can be deployed either locally or 
on a Kubernetes cluster and it is able to run user-defined functions. 

## Concepts

The main concepts behind the platform are:

### Function

A function is a unit of computation in the platform that can be created, deleted or invoked. 
It is fundamentally a wasm binary that can be uploaded to the platform with a name, and with an associated module. It should be a wasm 
executable that takes as input a json object and returns a json object. We currently support building
Rust code to wasm via our [CLI tool](https://github.com/funlessdev/fl-cli).

### Module
A module is a collection of functions under the same name. It is used to group functions together to avoid name collisions.
The idea is the same behind the concept of module/namespace/package in other languages.

Every FunLess instance has a default module called `_`, which is used when creating/invoking/deleting a new function without specifying a particular module.

### Events

FunLess implements its own version of event connectors that can be used to trigger functions.
When creating a new function, it is possible to "connect" it to an event source, which will trigger the function when a new event arrives.

Currently we only support an MQTT connector.

### Data Sinks

On the other side of the event connectors, we have the data sinks.
They are used to send the output of a function to a specific destination.
When creating a function, like for the events, it is possible to specify a data sink.

Currently we only support a CouchDB data sink, which stores all invocation results of the connected functions.

### Web Assembly

At the basis of the platform there is WebAssembly. We are using the [wasmtime](https://wasmtime.dev/) runtime to execute wasm binaries.
Web Assembly is a relatively new technology that is gaining a lot of traction in the industry, and it is a perfect fit for serverless platforms.
It is a portable, sandboxed, and secure execution environment that can be used to run untrusted code. 

Usually serverless platforms use 
either containers or VMs to setup an execution environment suitable for a function (js code needs nodejs, rust needs its toolchain installed etc/), introducing overhead and cold-start times. With WebAssembly we are dealing with a ready to run binary, since the function code is compiled beforehand into an executable, therefore we can avoid containers setup and just run the code instead, resulting in near 0 cold-start time.

## Architecture

### Core
At the heart of the platform there is the **Core** component, which is the orchestrator of the platform. It manages functions and modules using a Postgres database behind. When an invocation request arrives, it acts as a scheduler to pick one of the available **Worker** componets, and it then sends the request to the worker to invoke the function (with the wasm binary if missing).

The core code resides in the apps/core folder, it is a Phoenix application that exposes a json REST API.

### Worker

The Worker is the actual functions executor. It makes use of Rust NIFs to run user-defined functions via the wasmtime runtime.
The worker makes use of a cache to avoid requesting the same function multiple times, and it is able to run multiple functions in parallel.
When the core sends an invocation request, the worker first tries to find the function in the cache, if it is not present it requests back to 
the core the wasm binary. Then it executes the function and sends back the result to the core.

The worker code resides in the apps/worker folder.

### Prometheus

We are using Prometheus to collect metrics from the platform. Besides collecting metrics from the Core and Worker, it is 
used by the Core to access the metrics of the Workers to make scheduling decisions.

### Postgres

We are using Postgres as the platform database, used by the Core to store functions and modules.

## CLI

It is recommended to use our [FunLess CLI](https://github.com/funlessdev/fl-cli) to interact with the platform, as it makes it easy to
do a local deployment and to deal with modules, functions and kickstart new function projects.

## Developing FunLess

You need Elixir installed on your machine.

When working on the platform, there are several ways to run it with your changes.
One is using the cli to do a local deployment with custom images. The local deployment uses `docker compose`, which runs
the docker images of the core and worker components, but it can be customized with the `--core` and `--worker` flags to use custom images.
So after making a change to the code, you can build the docker images and run the local deployment with the custom images.

Another way is to run the core and worker components directly, either the realeses or with `iex -S mix` for an interactive session.
Note that this way you won't have prometheus running, so the core won't have access to metrics for scheduling.

### Running with iex

First of all you need to install the dependencies:

```bash
mix deps.get
```

Then you need to start the database, there is a docker-compose.yml file in the root of the project that can be used to start a postgres instance:

```bash
docker compose up -d
```

Now to run the Core: 

```bash
cd apps/core
mix ecto.setup
iex --name core@127.0.0.1 --cookie default_secret -S mix phx.server
```

For the Worker:

```bash
cd apps/worker && iex --name worker@127.0.0.1 --cookie default_secret -S mix
```

You can check if the 2 components are seeing each other by writing in the Core iex terminal:

```elixir
Node.list()
```

If it returns an empty list, connect them manually with:
  
```elixir
Node.connect(:"worker@127.0.0.1")
```

Note: you might get spammed with prometheus error logs because there is no prometheus running, but you can ignore it.

Now you can send requests to `localhost:4000`. The file `openapi/openapi.yaml` contains the OpenAPI specification of the API.

### Mix Release

The project can also be compiled as a release, and run like this:

For the Core: 
```
mix release core
./_build/dev/rel/core/bin/core start (or daemon to run it in the background)
```

For the Worker:
```
mix release worker
./_build/dev/rel/worker/bin/worker start (or daemon to run it in the background)
```

### Run Tests

The tests are divided in unit tests and integration tests (which need a postgres instance running).
For the unit tests from the root folder:

```bash
mix core.test
mix worker.test
```

For the integration tests:
  
```bash
core.integration_test
```

Or you can enter the core/worker folder and run the tests from there.

## Contributing

Anyone is welcome to contribute to this project or any other FunLess project. 

You can contribute by testing the projects, opening issues, writing documentation, sharing new ideas for future works and, of course,
by contributing code. 

You can pick an issue or create a new one, comment on it that you will take priority and then fork the repo so you're free to work on it.
Once you feel ready open a Pull Request to send your code to us.

## License

This project is under the Apache 2.0 license.

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

## v0.4.0 (2022-11-01)

### Feat

- **openwhisk**: remove adapter
- **openwhisk**: remove fn_docker nif
- **telemetry**: remove adapter
- **promex**: setup promex
- **wasm-module**: compile module in another thread
- implement the nif to run functions in another thread
- **openwhisk**: update openwhisk provisioner with container struct
- **structs**: remove runtime struct
- **wasm-adapter**: remove inner module cache
- remove runtime cache
- **resource-cache**: add ResourceCache to substitute RuntimeCache
- **wasm-module**: add module cache
- add ExecutionResource struct
- **wasm-engine**: add delete call to engine cache
- **wasm-module**: add module resource to compile wasm module
- **wasmtime**: add get_handle to retrieve engine handle
- **supervisor**: add swappable runtime supervisor
- **wasmtime**: add engine cache genserver to keep engine handle
- **fn_wasm**: add wasmtime engine as resource arc
- update provisioner with new cache insert
- **invoke**: update invoke with new cache
- remove cleanup all
- **cleanup**: update cleanup with cache
- **RuntimeCache**: implement new get, insert and delete with namespace
- **wasm**: add wasm runtime adapter
- **structs**: add wasm to runtime struct fields; code and image are no longer mandatory in function structs
- **wasm**: add wasm run_function nif
- **telemetry**: add telemetry supervisor and insert it in main supervision tree
- **telemetry**: add worker telemetry request server
- **telemetry**: add event handler and ets server for telemetry data
- **telemetry**: add resource monitoring function and telemetry event
- **nif**: add encoding for docker and timeout bollard errors in nifs
- **log**: add logging to file
- **runtime.exs**: make network name configurable with env var
- **openwhisk**: add support for docker-in-docker invocations
- **Docker**: add env var to change docker socket path

### Fix

- **license**: header
- **credo**: warnings
- **openwhisk**: provisioner
- **cleaner**: pass resource to cleaner instead of function
- **invoke_function**: use provision resource in domain
- **credo**: warnings
- **wasm**: encode function args as json string in invocation
- add alias
- parameters for invoke
- functionStruct passing to fix tests
- credo warning
- **wasm-provisioner**: fix code is not nil
- **license**: change license header with correct one
- **openwhisk**: fix dialyzer error
- **wasm**: correctly handle prepare_runtime with missing code
- **wasm**: add receive block to run_function
- **structs**: add default value for wasm in runtime struct
- **dyalizer**: add nowarn and fix dyalizer warnings
- **credo**: refactor for credo warnings
- **openwhisk**: remove runtime after failed init
- **openwhisk**: handle connection refused errors during runtime init
- **Docker**: socket proxy
- **nif**: add check for network name in runtime creation
- **license**: add license header

### Refactor

- update logs
- use pattern matching on resource
- update runner and cleaner ports
- **cleanup**: update domain cleanup
- **provision**: change provision runtime to provision resource
- **wasm-module**: use constants for names
- **wasm-engine**: use mutex to wrap engine and return a result
- small logs and specs update
- simplify api with provision and cleaner usage
- **provisioner**: rename prepare_runtime function to provision
- **cluster**: remove prepare and cleanup actions
- doc update and ignore dialyzer warning
- **RuntimeTracker**: change to RuntimeCache
- **fn_wasm**: separate run_function if statement in sub-functions
- **domain**: remove mandatory code and image from invoke and cleanup
- **config**: change default runtime from openwhisk to wasm
- **domain**: remove mandatory code and image in prepare_runtime
- rename fn to fn_docker
- **telemetry**: rename ets table to worker_telemetry_ets to avoid confusion with the worker_telemetry process
- **cleaner**: integrate ow cleaner code
- **runner**: integrate ow run code
- **provisioner**: integrate ow prepare and init code
- **cluster**: uncomment and update cluster requests
- **docker_socket**: add docker_socket function in Application
- integrate invoke_function and some polishing
- **cleaner**: add cleaner use in domain with tests
- **provision_ets_test**: move provisioner stub in setup
- **provisioner**: change api prepare in provision_runtime with more tests
- restructure code with new runtime ports
- **runtime**: break up runtime port/adapter in 4 components
- **logs**: change log location to /tmp/funless
- **tests**: divide tests in unit and integration folders
- **openwhisk**: add error and info logs in cleanup
- **openwhisk**: separate init in multiple functions with logs

### Perf

- **openwhisk**: remove hardcoded timer in runtime init

## v0.3.0 (2022-08-11)

### Refactor

- **api_tests**: separate api tests in different files
- **nif**: remove rust logging in get_image
- **openwhisk**: move openwhisk nifs to separate submodule
- **js**: remove unused folder
- **api**: split api module in prepare, invoke, cleanup submodules
- move function_storage_test to runtime_tracker_test
- rename FunctionStorage to RuntimeTracker
- move function and runtime structs in structs.ex with Struct suffix to make them clearer and avoid conflicts
- **Cluster**: simplify cluster by separating the genserver code to the api calls and move invocation logic into domain
- **Cleanup**: remove function argument from cleanup
- **FunctionStorage**: refactor function storage methods
- some polishing for the type specs used and logs

### Feat

- swap node connection with libcluster gossip
- add start phase to connect to a core node passed with env var
- **structs**: update function struct to include code and namespace; remove archive and main_file from struct
- **api**: add cleanup_all to delete all runtimes associated with a function
- **Runtime**: integrate fn rust module into openwhisk runtime

### Perf

- **openwhisk**: compute docker_socket only once as application env variable

### Fix

- **runtime.exs**: core env var required only in production
- **openwhisk**: return correct payload encoding for openwhisk runtimes
- **function-storage**: fix table used to not override new insertions
- convert struct to function struct for the rustler nif
- **Cleanup**: all cleanup methods return the entire runtime struct instead of only the name
- **Fn**: fix struct name definition compatible with Runtime struct in elixir

## v0.2.0 (2022-07-14)

### Refactor

- rename all containers references to runtime
- rename containers module into runtime
- **logs**: small logs refactor to make it logs more clear
- small refactor to ease adding logs in the worker
- remove rootless boolean flag from prepare_container
- **fn**: change prepare_container return type to struct
- **js**: move js example file to top-level folder
- **check.yml**: rename ci tasks
- rewrite worker application following hexagonal architecture
- move genserver to separate file; merge worker and function
- refactor worker as genserver; add updater for state preservation in ets
- **Worker**: refactor worker as an elixir application
- **.gitignore**: fix target/ directory not being ignored correctly
- **fn**: move rust code to native/fn directory
- delete fn submodule
- **license**: add license header to atoms.rs
- **funless-fn**: move submodule from funless-fn to fn
- **license**: add license header to nif.rs
- move get_image and start_container out of setup_container

### Fix

- **FunctionStorage**: fix crashing logs in function storage cause by container struct
- **nodejs-runtime**: add latest tag to nodejs runtime
- **api.ex**: add check in cleanup
- **license**: add license header to tests; ignore eex files in license checks
- fix rustler init and return types

### Feat

- **cluster.ex**: add support for function args in genserver calls
- switch function containers to openwhisk nodejs runtime
- **worker.ex**: add invoke_function
- add support for default docker installation
- **worker.ex**: add basic worker behaviour
- parameterize all NIFs; handle messages from NIFs' environment
- **nif.rs**: parameterize all NIFs; move all NIFs to non-BEAM thread
- add funless-fn NIF module
- **nif.rs**: implement run_function() and cleanup() NIFs
- create project with funless-fn submodule
- **nif.rs**: add initial rustler integration
- execute external code inside container
- add initial bollard functions

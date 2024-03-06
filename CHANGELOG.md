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

## v0.9.0 (2024-03-06)

### Feat

- **core**: add prometheus_host env var
- **worker**: add ResourceCache time-based and entry-based eviction
- **worker**: migrate ResourceCache to cachex
- **core**: handle function hash in delete/invoke/create/update
- **worker**: handle function hashes in invoke/delete/update
- **worker**: handle hash in ResourceCache
- **worker**: handle hash in RawResourceStorage
- **core**: add hash field to functions
- **core**: store function code after creation
- **worker**: add raw resource lookup in invoke
- **worker**: add store_resource endpoint
- **worker**: add raw resource storage port, adapter and mock
- **core**: rewrite scheduler using SchedulingPolicy module
- add create and get endpoints for app scripts
- add APP script migration and schema
- add APP script endpoints
- add push/scrape for all metrics on prometheus
- **worker**: add concurrent functions count in invoke
- add node name exchange at monitoring start
- **worker**: remove node_info telemetry; add node_info at setup time
- **worker**: add cachex to handle node info
- **worker**: add telemetry and cluster request for node info
- **core**: add empty config data type and default scheduler
- **policies**: add app-based scheduling algorithm
- **data**: add function metadata struct; add missing data docs
- **core**: add app parser; add scheduling_policy protocol
- expand worker data type; refactor worker metrics as struct

### Fix

- **Makefile**: remove extra --build-arg
- **worker**: correctly set ResourceCache env
- **worker**: handle saved hash removal in delete
- **worker**: handle :noproc monitor msg in raw storage
- improve error handling when storing functions
- **worker**: fix broken store_function call
- **core**: move store_on_create to runtime config
- **core**: handle EmptyError in default policy select
- **core**: increase invocation timeout
- **core**: start telemetry supervisor before libcluster
- **core**: handle dialyzer errors
- **worker**: declass args log from info to debug
- remove debug logs in prod
- **core**: handle missing resources case in scheduler
- update link for core ci badge in readme
- **worker**: fix broken function call
- license header
- **policies**: add missing capacity check on workers in app/default policies
- **parsers**: handle block errors and atom loading in app

### Refactor

- **worker**: fix linter warnings
- **worker**: remove unused definition
- **core**: improve store_on_create handling
- **core**: remove one-worker case in scheduling
- **worker**: add ephemeral genserver to handle invocations with missing code
- **core**: remove double sending of args in invoke/invoke_with_code
- **core**: fix credo warnings
- remove views and update with verified routes
- **core**: migrate to phx 1.7
- turn into monorepo and clean up files
- **data**: move data to its own project
- **core**: move core to its own project
- **worker**: move worker app into its own project
- **policies**: handle credo and typing issues in app
- **policies**: add missing typespec and function arg in app schedule()
- **policies**: simplify app scheduling pipeline
- handle dialyzer warnings
- **policies**: remove inefficient enum; refactor with to case

## v0.8.0 (2023-04-04)

### Feat

- **core**: save guest/admin tokens on external file
- **core**: add admin authentication for subject endpoints
- add admin context/schema/migration
- **worker**: add http request import for wasm
- **core**: add cache between subject db and auth check
- **core**: add phx.token and auth plug
- **core**: add subject_by_name and small changes
- **core**: improve subject schema with regex, index on name and redact token
- **core**: gen simple subject table and configure testing
- **core**: add new repo for subjects database
- **core**: add get route for health checks

### Fix

- **core**: 404 when list on non-existent module (#176)
- **core**: return err when deleting default module (#152)
- **core**: return error when fn already exists (#168)
- **core**: check function exists then pick worker (#157)
- **release**: handle subjectsrepo seeding in release
- **openapi**: create subject result schema
- **worker**: fix crash in http imports
- **core**: add error, any match in fallback controller
- **core**: add more checks in auth.ex
- update license date

### Refactor

- **token**: fix credo warnings
- **worker**: update runner with wasmex and imports
- **worker**: update provisioner and fix dialyzer warnings
- **worker**: remove rustler nif with wasmex rewrite
- **core**: disable unused plugs

## v0.7.0 (2023-01-26)

### Feat

- **worker**: add promex plugin to expose os_mon metrics
- **core**: add prom_ex ecto and os_mon metrics for dev dashboard
- **core**: add mongodb sink and contact all data sinks on invoke result
- **core**: setup data_sink port/adapter like connector
- **openapi**: add data sinks

### Fix

- **core**: change get_module_by_name to not raise and use it in with
- **core**: when function delete don't return :not_found if events/sinks do not exist
- **core**: credo warnings
- **core**: events and sinks render parameters handling
- **core**: update function controller/view with data sinks responses
- **core**: add module name in get module response
- **openapi**: fix missing model in generated sdk
- **core**: parse events string in function_controller

### Refactor

- **core**: metrics collector update
- **core**: switch to couchdb with simple http post request
- **core**: update mongodb params and invoker function name
- **worker**: update some logs
- **core**: make connector manager code more clear
- **openapi**: revert openapi spec to v3.0.2
- **openapi**: update openapi and gen sdk action

### Perf

- **core**: remove atom generation in mqtt connector

## v0.6.0 (2022-12-25)

### Feat

- **openapi**: add 207 response to create and update
- **core_web**: add view in function_controller for function+events
- **core_web**: add event connect/disconnect in function_controller
- **core**: add wrapper for event connector manager in domain
- **openapi**: add connected events to function create/update
- **core**: handle migrations and seed when deploying core
- **connectors**: add function invocation in mqtt connector
- **connectors**: add mqtt connector genserver
- **core**: use db with invoker
- **connectors**: add supervisor and dynamic supervisor for child processes
- **connectors**: add connector manager adapter, ets store and example process
- **connectors**: update manager specification
- **data**: add connected event data type
- **connectors**: update connector manager spec
- **connectors**: add connector manager port
- **core**: finish implementation of list,create,update,delete
- **core**: implement list functions in a module route
- **core**: seed db with default module '_'
- **core**: generate functions json api
- **core**: add phx generated module api
- **core**: setup ecto

### Fix

- **core**: add correct list match in domain.events
- **connectors**: handle string key and params in mqtt
- **mix.exs**: fix ecto.setup command in core
- **core**: add start if node_ip in server script
- **core**: add license header and credo warnings
- **openapi**: fix wrong schema file name
- **core**: add composite unique constraint in functions on name+module_id
- **core**: remove module_id unique constraint in functions table
- **core_web**: add catch-all case for update; handle missing tmp file for plug; add name in update
- **connectors**: remove :ok return value in manager.disconnect
- **openapi**: fix function create/update type and params
- **connectors**: handle registered stopped supervisor in manager
- **core_web**: add missing case in function_controller
- **connectors**: handle exit messages in mqtt connector
- **connectors**: remove ets table; handle connector restart
- **core_web**: fix create with file upload in function_controller
- **core**: fix dialyzer warning
- **connectors**: fix manager adapter return types
- **data**: fix type in connected event struct
- **connectors**: set correct table type
- **core**: dialyzer warning
- **core**: regex accepts underscores as first and last char
- **core**: add cascading delete on functions
- **license**: add header
- **openapi**: operation id repeated

### Refactor

- **core_web**: remove todos in function_controller
- **core_web**: fix some credo warnings in function_controller
- **openapi**: merge function create+update schema
- **connectors**: fix credo warnings
- **connectors**: add missing license header
- **connectors**: add mqtt init typespec
- **connectors**: update manager spec for easier testing
- **connectors**: fix credo warning in mqtt
- **core**: update invoker checks and reorganize tests
- **core**: remove function store port/adapter
- **core**: update docs and functions context
- **connectors**: add example call to stub connector
- **core**: add get_by_name for functions and modules
- **core**: update routes to match openapi spec
- **openapi**: update spec with new function api
- **makefile**: remove help
- **openapi**: uncomment fn api
- **openapi**: reorganize spec structure with new modules api
- **core**: reorganize test folders
- **structs**: add data app to hold core and worker structs
- swap namespace naming to module
- **core**: join core and core_web apps in a single phoenix app

## v0.5.0 (2022-11-26)

### Feat

- **worker**: merge fl-worker as child app

- **api**: add check for empty/nil/blank namespace
- add list_functions endpoint
- **function_store**: add list_functions callback in function store
- **core-api.yaml**: add list endpoint to core-api
- add optional kubernetes libcluster strategy
- add optional kubernetes libcluster strategy
- **Dockerfile**: add configurable node_ip env in dockerfile
- **Dockerfile**: add configurable node_ip env in dockerfile
- **delete**: add 404 return response for delete
- **delete**: move exist check into function_repo delete
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
- swap node connection with libcluster gossip
- add start phase to connect to a core node passed with env var
- **structs**: update function struct to include code and namespace; remove archive and main_file from struct
- **api**: add cleanup_all to delete all runtimes associated with a function
- **Runtime**: integrate fn rust module into openwhisk runtime
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

### Fix

- handle function exec_error
- return an {:error, {:exec_error, msg}} when fn exec crashes
- **Dockerfile**: revert alpine version to 3.16
- **core-api.yaml**: set correct type for function_list_success
- **core-api.yaml**: set correct type for namespace in fn list
- **function_repo**: correctly handle db errors in list()
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
- **runtime.exs**: core env var required only in production
- **openwhisk**: return correct payload encoding for openwhisk runtimes
- **function-storage**: fix table used to not override new insertions
- convert struct to function struct for the rustler nif
- **Cleanup**: all cleanup methods return the entire runtime struct instead of only the name
- **Fn**: fix struct name definition compatible with Runtime struct in elixir
- **FunctionStorage**: fix crashing logs in function storage cause by container struct
- **nodejs-runtime**: add latest tag to nodejs runtime
- **api.ex**: add check in cleanup
- **license**: add license header to tests; ignore eex files in license checks
- fix rustler init and return types

### Refactor

- **worker**: integrate worker as child app
- **function_repo**: fix dialyzer error
- **fn_controller**: remove unused case in list()
- **core-api**: remove unused return case
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

## v0.4.0 (2022-10-31)

### Feat

- remove image field in FunctionStruct
- **metrics**: update metrics adapter
- **promex**: setup promex
- separate invoke in without and with code versions
- **mnesia**: add exists? function
- remove http server adapter
- **core-api**: change create code to 201 and delete to 204
- **invoke**: migrate invoke to phoenix api
- **delete**: add /fn/delete endpoint to delete functions in storage
- **fn-create**: add fn_view to handle success create case
- fn create handle database error case
- **FunctionStruct**: make image field optional
- **fn-api**: add route to /v1/fn/create
- **core-api**: remove image field in create and update endpoints with v1
- add get and delete error types in function storage
- add result struct for better type specs
- add type specs
- **config**: disable pubsub and liveview
- **core-api**: update endpoints
- disable code reload and live socket
- remove gettext and use bandit
- add core web umbrella child
- **config**: add phoenix related configs
- **scheduler**: add super simple scheduling over cpu utilization
- **telemetry**: add dynamic supervisor for subprocesses
- **application**: add telemetry supervisor to main supervision tree
- **telemetry**: add native telemetry supervisor for ets server and collector
- **telemetry**: add telemetry collector for worker resources
- **telemetry**: add native telemetry api and ets server
- **telemetry**: add telemetry api port
- **logs**: add logging to file for prod release
- **server**: add json header to error replies
- **server**: add specific error message for timeouts

### Fix

- **core-api**: update error status code
- **promex**: use correct router/endpoint modules
- **logs**: remove log when saving metrics
- credo and dialyzer errors
- **fn_controller**: handle missing file upload in create
- **fn_controller**: correctly handle file upload in phoenix
- **config**: revert libcluster port to default; add env var to edit it
- **core-api**: remove incorrect property type
- **core-api**: change fn/create to multipart/form-data, with code as binary
- **invoker**: log message
- dashboard and libcluster used port
- **logs**: remove spammy logs
- unify return types to result struct and enable json encoder
- remaining types and pattern matching on error
- **license**: add license header
- move credo dialyzer to root mix and fix their warnings
- **license**: change with correct license header
- **scheduler**: use workers we have the metrics for
- **config**: remove deprecated $levelpad
- **telemetry**: handle error|ok tuples in collector
- **telemetry**: change table name to correct value
- **server**: add missing "result" wrapper to successful function invocation
- **invoker.ex**: fix log error message

### Refactor

- **delete**: change status code to 200
- **controller**: return json directly from controller
- **mnesia**: add check in delete
- change dialyzer setup and function repo logs
- **scheduler**: update scheduler to for the simple memory metrics
- revert phoenix adapter to cowboy, remove bandit deps
- improve logs
- swap :warn :code_not_found to :error
- **invoker**: handle first invoke without code and retry with code
- change functionStorage to functionStore
- merge db error and update error messages
- **invoke-result**: update doc and add in worker adapter spec
- rename IvkResult to InvokeResult
- **ivkresult**: add ivkresult to worker adapter
- **controller-tests**: add assertion helper to polish tests
- change ResultStruct to IvkResult
- **error_view**: simplify db error case
- **function-api**: use string as return type and improve docs and specs
- **function**: change name Api.Function to Api.FunctionRepo
- move core to apps as umbrella child
- **mix.exs**: change to umbrella organization
- swap monitor and collector names
- change information_retriver to monitor and more pipelines
- **logs**: move log file in /tmp/funless
- **invoker**: fix invoke type signature
- **core-api.yaml**: add explicit declaration of responses as schemas
- **worker**: reduce invocation timeout to 30s

## v0.3.0 (2022-08-11)

### Refactor

- **tests**: refactor tests into unit and integration tests
- **api_test**: remove unused alias
- **configs**: group libcluster configs in config.exs
- **tests**: add separate http and api tests in multiple files and extract common assertions
- **api**: separate api in invoker and function modules
- **http_server**: update bad_params error message
- **api**: change new_function and delete_function return types for easier json integration
- **api**: change delete_function params to map
- **mnesia**: rename namespaced_name to namespace_name and add documentation on the field
- **structs**: rename "language" field in FunctionStruct to "image"
- simplify invoke param validation with struct
- **api**: change ivk_params type to map
- **Worker**: refactor worker code with a couple of tests
- refactor type specs and update code
- remove dead code: FnWorker struct
- add licenses and fix alias ordering
- **commands**: update docs and type for send_invocation_command
- **logs**: make some logs clearer and up log level for tests
- **Invoker**: remove internal invoker
- **Scheduler**: move scheduler from rust module to built-in elixir module
- simplify logs and invoke call

### Fix

- **test**: fix missing libcluster config in test environemnt
- **function**: fix log message in new
- **http_server**: change transaction aborted status code from 404 to 500
- **server**: add custom message for function not_found error
- **application**: fix init_database being called in test environment
- **Dockerfile**: add missing lib
- license header and windows env
- parse worker reply to handle error case with 500 status reply
- **api**: add namespace params as required to limit combinations
- **api**: add simple ivk params validation
- **worker**: remove tuple wrapper from worker reply
- **worker**: fix log crash
- **worker**: wrap worker reply in a :ok tuple
- **Dockerfile**: fix version passed to docker build
- **Dockerfile**: remove 'v' char from version
- **Image-Action**: fix build-args List syntax
- **config.exs**: change :prod cookie to sample atom
- **worker.ex**: change old :prepare to :invoke in GenServer.Call

### Feat

- add PORT env var to customize bandit server port
- **libcluster**: add libcluster with Gossip strategy for dev environment
- **server**: add error handling for json decoding and generic crashes
- **http_server**: add endpoints for function creation and deletion
- **api**: add :bad_params case for new_function
- **application**: add init_database on core nodes as application start phase
- **nodes**: add core_nodes list extraction in domain
- rewrite function invocation
- **api**: add api calls for function creation and deletion
- **function_storage**: add node list as param to init_database; fix delete_function behaviour in mnesia
- **mnesia**: add mnesia adapter for function storage
- **function_storage**: add function_storage port and move structs to separate file
- **httpserver**: implement post endpoint following openapi spec
- **worker**: add genserver call to worker

## v0.2.0 (2022-07-14)

### Fix

- **worker**: wrap worker reply in a :ok tuple
- **Dockerfile**: fix version passed to docker build
- **Dockerfile**: remove 'v' char from version
- **Image-Action**: fix build-args List syntax
- **config.exs**: change :prod cookie to sample atom
- **worker.ex**: change old :prepare to :invoke in GenServer.Call

### Refactor

- add licenses and fix alias ordering
- **commands**: update docs and type for send_invocation_command
- **logs**: make some logs clearer and up log level for tests
- **Invoker**: remove internal invoker
- **Scheduler**: move scheduler from rust module to built-in elixir module
- simplify logs and invoke call
- add cluster port to be used to get info from the cluster
- change architecture to hexagonal (ports and adapters)
- **scheduler**: Integrate scheduler to repo
- **license**: add license header

### Feat

- **httpserver**: implement post endpoint following openapi spec
- **worker**: add genserver call to worker
- rename router to server and wire it up with the invoke + tests
- add internal invoker api used to send invoke commands
- add worker selection and genserver call to worker
- **scheduler**: remove stub functions and define select
- implement simple router
- add bandit server with supervisor

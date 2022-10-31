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
- **Worker**: fix log crash
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

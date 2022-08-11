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

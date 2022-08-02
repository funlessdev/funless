## v0.3.1 (2022-08-02)

### Fix

- license header and windows env

## v0.3.0 (2022-08-02)

### Fix

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

### Refactor

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

### Feat

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
- **scheduler**: add funless-scheduler as a submodule

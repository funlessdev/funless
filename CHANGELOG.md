## v1.0.1 (2022-06-17)

### Fix

- **config.exs**: change :prod cookie to sample atom

## v1.0.0 (2022-06-15)

### Fix

- **worker.ex**: change old :prepare to :invoke in GenServer.Call

### Feat

- **worker**: add genserver call to worker
- rename router to server and wire it up with the invoke + tests
- add internal invoker api used to send invoke commands
- add worker selection and genserver call to worker
- **scheduler**: remove stub functions and define select
- implement simple router
- add bandit server with supervisor
- **scheduler**: add funless-scheduler as a submodule

### BREAKING CHANGE

- core is ready for sample pipeline

### Refactor

- add cluster port to be used to get info from the cluster
- change architecture to hexagonal (ports and adapters)
- **scheduler**: Integrate scheduler to repo
- **license**: add license header

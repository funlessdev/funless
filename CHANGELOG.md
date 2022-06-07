## 1.0.0 (2022-06-07)

### Refactor

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

- **api.ex**: add check in cleanup
- **license**: add license header to tests; ignore eex files in license checks
- fix rustler init and return types

### Feat

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

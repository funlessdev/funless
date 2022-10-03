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

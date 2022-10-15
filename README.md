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

# Funless Worker

## Running in an interactive session

The project can be run in an interactive session by running:
```
mix deps.get
mix compile
iex -S mix
```

To test the main worker behaviour, run:
```
fcode = "function main(params) {\nlet name = params.name || \"World\"\nreturn { payload: `Hello ${name}!` }\n}"

function = %{name: "hellojs", image: "nodejs", code: fcode, namespace: "_"}

GenServer.call(:worker, {:prepare, function})
GenServer.call(:worker, {:invoke, function})
GenServer.call(:worker, {:cleanup, function})
```

The `:prepare` call is optional, as `:invoke` creates the container if none is found.

___

## Running in different nodes

The project can also be compiled as a release, and run like this:
```
mix release
./_build/dev/rel/worker/bin/worker start (or daemon to run it in the background) and stop 
```

And on a different terminal session, start the interactive session like this:
```
iex --name n1@127.0.0.1 --cookie default_secret -S mix
```

And run:
```
fcode = "function main(params) {\nlet name = params.name || \"World\"\nreturn { payload: `Hello ${name}!` }\n}"

function = %{name: "hellojs", image: "nodejs", code: fcode, namespace: "_"}

GenServer.call({:worker, :"worker@127.0.0.1"}, {:invoke, function})
```

The `--cookie` and `--name` parameters can vary; the `--cookie` must be the same used in compiling the release, defined in `rel/env.sh.eex`.

___

## Running with Docker

To run with Docker, the image can be built from source:
```
docker build -t <IMAGE_NAME> .
```

Afterwards, a network should be created to allow containers to communicate with each other (and therefore, to allow the Worker to communicate with runtimes):
```
docker network create <NETWORK_NAME> --internal
```

The network should be internal, to as the worker gets its name and address from the external, worker-to-core network, and this avoids conflicts.


Then, the container can be created using:
```
docker create -v /var/run/docker.sock:/var/run/docker-host.sock --network=<NETWORK_NAME> --env RUNTIME_NETWORK=<NETWORK_NAME> <IMAGE_NAME>
```

Or, in a rootless installation:
```
docker create -v /run/user/1001/docker.sock:/var/run/docker-host.sock --network=<NETWORK_NAME> --env RUNTIME_NETWORK=<NETWORK_NAME> <IMAGE_NAME>
```

Where `/run/user/1001/docker.sock` must be set to the value of the `$DOCKER_HOST` environment variable, minus the protocol (e.g. `unix:///run/user/1001/docker.sock` -> `/run/user/1001/docker.sock`).

Finally, the container can be attached to a second network (to which the `fl-core` container is also attached):
```
docker network connect <SECOND_NETWORK_NAME> <CONTAINER_NAME>
```

And then started:
```
docker container start <CONTAINER_NAME>
```

(containers have to be first connected to multiple networks, and then started, as stated here https://github.com/moby/moby/issues/17750).

## Contributing
Anyone is welcome to contribute to this project or any other Funless project. 

You can contribute by testing the projects, opening tickets, writing documentation, sharing new ideas for future works and, of course, by contributing code. 

You can pick an issue or create a new one, comment on it that you will take priority and then fork the repo so you're free to work on it.
Once you feel ready open a Pull Request to send your code to us.

## License

This project is under the Apache 2.0 license.
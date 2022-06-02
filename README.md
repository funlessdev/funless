# FunlessWorker

## Running in an interactive session

The project can be run in an interactive session by running:
```
mix deps.get
mix compile
iex -S mix
```

To test the main worker behaviour, run:
```
GenServer.call(:worker, {:prepare, %{name: "hellojs", image: "node:lts-alpine", main_file: "/opt/index.js", archive: "js/hello.tar.gz"}})
GenServer.call(:worker, {:invoke, %{name: "hellojs", image: "node:lts-alpine", main_file: "/opt/index.js", archive: "js/hello.tar.gz"}})
GenServer.call(:worker, {:cleanup, %{name: "hellojs", image: "node:lts-alpine", main_file: "/opt/index.js", archive: "js/hello.tar.gz"}})
```

The `:prepare` call is optional, as `:invoke` creates the container if none is found.

___

## Running in different nodes

The project can also be compiled as a release, and run like this:
```
mix release
./_build/dev/rel/worker/bin/worker start
```

And on a different terminal session, start the interactive session like this:
```
iex -S mix --name n1@127.0.0.1 --cookie default_secret
```

And run:
```
GenServer.call({:worker, :"worker@127.0.0.1"}, {:invoke, %{name: "hellojs", image: "node:lts-alpine", main_file: "/opt/index.js", archive: "js/hello.tar.gz"}})
```

The `--cookie` and `--name` parameters can vary; the `--cookie` must be the same used in compiling the release, defined in `rel/env.sh.eex`.

___

## Code structure

The code has been structured following hexagonal architecture principles; the main components are shown in the picture, divided in ports (blue circles), adapters (green circles) and core domain (inner hexagon).

![](docs/Worker_hexagonal.svg)
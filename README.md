# Core
[![Funless CI](https://github.com/funlessdev/funless-core/actions/workflows/check.yml/badge.svg)](https://github.com/funlessdev/funless-core/actions/workflows/check.yml)

This is the repository for the Core component of the Funless (FL) platform, a new generation research-driven serverless platform. 

The Core is written in Elixir and (as of now) handles http requests to upload, invoke and delete Javascript functions. 
It does so through the [Bandit](https://github.com/mtrudel/bandit) http server, 
it saves functions using Mnesia and launches them by sending a message to our [Worker](https://github.com/funlessdev/funless-worker) component, 
which takes care of executing functions and returning their results.
### Running in an interactive session
The project can be run in an interactive session by running:

```sh
mix deps.get
mix compile
iex -S mix
```

Now you can send post requests to `localhost:4001`. The file `core-api.yaml` contains an OpenAPI specification of the possible requests.

First you should create a function, send a POST request to `localhost:4001/create` with the following body:
```json
{
  "name": "hello",
  "namespace": "_",
  "code": "function main(params) {\nlet name = params.name || \"World\"\nreturn { payload: `Hello ${name}!` }\n}",
  "image": "nodejs"
}
```

You should receive as response: `{ "result": "hello" }`.

After that you can send a POST request to `localhost:4001/invoke` with the following body:
```json
{
  "namespace": "_",
  "function": "hello",
  "args": {}
}
```

You have no connected worker to use, so you will receive the error:
```json
{
  "error": "Failed to invoke function: no worker available"
}
```

Re-run the project with `iex --name <a-name>@<something> -S mix` and run the [Worker](https://github.com/funlessdev/funless-worker) project as well. 
Then connect the Core with the Worker using `Node.connect`. Now you have a worker to use for that function.

### Mix Release


The project can also be compiled as a release, and run like this:

```
mix release
./_build/dev/rel/core/bin/core start (or daemon to run it in the background) and stop 
```

## Contributing
Anyone is welcome to contribute to this project or any other Funless project. 

You can contribute by testing the projects, opening tickets, writing documentation, sharing new ideas for future works and, of course,
by contributing code. 

You can pick an issue or create a new one, comment on it that you will take priority and then fork the repo so you're free to work on it.
Once you feel ready open a Pull Request to send your code to us.


## License

This project is under the Apache 2.0 license.
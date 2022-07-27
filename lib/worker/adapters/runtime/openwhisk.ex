# Licensed to the Apache Software Foundation (ASF) under one
# or more contributor license agreements.  See the NOTICE file
# distributed with this work for additional information
# regarding copyright ownership.  The ASF licenses this file
# to you under the Apache License, Version 2.0 (the
# "License"); you may not use this file except in compliance
# with the License.  You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing,
# software distributed under the License is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
# KIND, either express or implied.  See the License for the
# specific language governing permissions and limitations
# under the License.
#

defmodule Worker.Adapters.Runtime.OpenWhisk do
  @moduledoc """
    Docker adapter for runtime manipulation. The actual docker interaction is done by the Fn NIFs.
  """
  @behaviour Worker.Domain.Ports.Runtime
  use Rustler, otp_app: :worker, crate: :fn
  require Logger
  alias Worker.Domain.RuntimeStruct

  #   Creates the `_runtime_name` container, with information taken from `_function`.
  #   ## Parameters
  #     - _function: Worker.Domain.Function struct, containing function information
  #     - _runtime_name: name of the container that will be created
  #     - _docker_host: path of the docker socket in the current system
  @doc false
  def prepare_runtime(_function, _runtime_name, _docker_host) do
    :erlang.nif_error(:nif_not_loaded)
  end

  #   Gets the logs of the `_runtime_name` container.
  #   ## Parameters
  #     - _runtime_name: name of the container
  #     - _docker_host: path of the docker socket in the current system
  @doc false
  def runtime_logs(_runtime_name, _docker_host) do
    :erlang.nif_error(:nif_not_loaded)
  end

  #   Removes the `_runtime_name` container.
  #   ## Parameters
  #     - _runtime_name: name of the container that will be removed
  #     - _docker_host: path of the docker socket in the current system
  @doc false
  def cleanup_runtime(_runtime_name, _docker_host) do
    :erlang.nif_error(:nif_not_loaded)
  end

  @doc """
    Checks the DOCKER_HOST environment variable for the docker socket path. If an incorrect path is found, the default is used instead.

    Returns the complete socket path, protocol included.
  """
  def docker_socket do
    default = "unix:///var/run/docker.sock"
    docker_env = System.get_env("DOCKER_HOST", default)

    case Regex.run(~r/^((unix|tcp|http):\/\/)(.*)$/, docker_env) do
      nil -> default
      [socket | _] -> socket
    end
  end

  @doc """
    Creates a runtime for the given `worker_function` and names it `runtime_name`.

    Returns {:ok, runtime} if no errors are raised;
    returns {:error, err} if any error is raised, forwarding the error message.

    ## Parameters
      - worker_function: Worker.Domain.Function struct, containing the necessary information for the creation of the runtime
      - runtime_name: name of the runtime being created
  """
  @impl true
  def prepare(function, runtime_name) do
    socket = docker_socket()

    Logger.info("OpenWhisk Runtime: Creating runtime for function '#{function.name}'")

    prepare_runtime(function, runtime_name, socket)

    receive do
      {:ok, runtime = %RuntimeStruct{host: host, port: port}} ->
        :timer.sleep(1000)
        code = File.read!(function.archive)

        body =
          Jason.encode!(%{
            "value" => %{"code" => code, "main" => "main", "env" => %{}, "binary" => false}
          })

        request = {"http://#{host}:#{port}/init", [], ["application/json"], body}
        _response = :httpc.request(:post, request, [], [])

        {:ok, runtime}

      {:error, err} ->
        {:error, err}

      something ->
        {:error, "OpenWhisk Runtime: Unexpected response from runtime: #{inspect(something)}"}
    end
  end

  @doc """
    Runs the function wrapped by the `runtime` runtime.

    Returns {:ok, results} if the function has been run successfully;
    returns {:error, err} if any error is raised, forwarding the error message.

    ## Parameters
      - _worker_function: Worker.Domain.Function struct; ignored in this function
      - runtime: struct identifying the runtime
  """
  @impl true
  def run_function(_worker_function, args, runtime) do
    Logger.info("OpenWhisk Runtime: Running function on runtime '#{runtime.name}'")
    body = Jason.encode!(%{"value" => args})

    request = {"http://#{runtime.host}:#{runtime.port}/run", [], ["application/json"], body}
    response = :httpc.request(:post, request, [], [])

    case response do
      {:ok, {_, _, payload}} ->
        Logger.info("OpenWhisk Runtime: Function executed successfully")
        {:ok, Jason.decode!(payload)}

      {:error, err} ->
        Logger.error("OpenWhisk Runtime: Error while running function: #{err}")
        {:error, err}
    end
  end

  @doc """
    Removes the `runtime` runtime.

    Returns {:ok, runtime} if the runtime is removed successfully;
    returns {:error, err} if any error is raised, forwarding the error message.

    ## Parameters
      - runtime: struct identifying the runtime being removed
  """
  @impl true
  def cleanup(runtime) do
    Logger.info("OpenWhisk Runtime: Removing runtime '#{runtime.name}'")
    cleanup_runtime(runtime.name, docker_socket())

    receive do
      :ok -> {:ok, runtime}
      {:error, err} -> {:error, err}
    end
  end
end

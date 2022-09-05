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
  require Logger

  alias Worker.Adapters.Runtime.OpenWhisk.Nif
  alias Worker.Domain.FunctionStruct
  alias Worker.Domain.RuntimeStruct

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
  def prepare(%FunctionStruct{} = function, runtime_name) do
    {:ok, socket} = Application.fetch_env(:worker, :docker_host)
    {:ok, max_retries} = Application.fetch_env(:worker, :max_runtime_init_retries)
    {:ok, network_name} = Application.fetch_env(:worker, :runtime_network_name)

    Logger.info(
      "OpenWhisk: Creating runtime for function '#{function.name}' using #{socket}, max_retries: #{max_retries}, network: #{network_name} "
    )

    Nif.prepare_runtime(function, runtime_name, network_name, socket)

    receive do
      {:ok, runtime = %RuntimeStruct{}} ->
        init_runtime(function, runtime, max_retries)

      {:error, err} ->
        {:error, err}

      something ->
        {:error, "OpenWhisk: Unexpected response from runtime: #{inspect(something)}"}
    end
  end

  # sends function to /init endpoint of the OpenWhisk runtime
  # if the runtime refuses the connection (i.e. not ready yet), waits 0.01 seconds and retries at most max_retries times
  defp init_runtime(_function, runtime, 0 = _retries_left) do
    Logger.error("OpenWhisk: runtime initialization failed.")

    case cleanup(runtime) do
      {:ok, _} ->
        {:error, :max_runtime_init_retries_reached}

      {:error, cleanup_err} ->
        {:error, {:max_runtime_init_retries_reached, {:error, cleanup_err}}}
    end
  end

  defp init_runtime(function, runtime, retries_left) do
    Logger.info("OpenWhisk: Initializing runtime for function '#{function.name}'")

    response = send_init(runtime.host, runtime.port, function.code)

    case response do
      {:ok, _} ->
        reply_from_init({:ok, runtime})

      {:error, :socket_closed_remotely} ->
        retry_init(function, runtime, retries_left)

      {:error, {:failed_connect, [{:to_address, _}, {_, _, :econnrefused}]}} ->
        retry_init(function, runtime, retries_left)

      {:error, err} ->
        case cleanup(runtime) do
          {:ok, _} -> reply_from_init({:error, err})
          {:error, cleanup_err} -> reply_from_init({:error, {err, {:error, cleanup_err}}})
        end
    end
  end

  defp reply_from_init({:ok, runtime}) do
    Logger.info("OpenWhisk: Runtime #{runtime.name} initialized")
    {:ok, runtime}
  end

  defp reply_from_init({:error, err}) do
    Logger.error("OpenWhisk: Runtime initialization failed: #{inspect(err)}")

    {:error, err}
  end

  defp retry_init(function, runtime, retries_left) do
    Logger.warn("OpenWhisk: failed to initialize runtime, retrying...")
    :timer.sleep(10)
    init_runtime(function, runtime, retries_left - 1)
  end

  defp send_init(host, port, code) do
    Logger.info("OpenWhisk: sending init request to runtime at #{host}:#{port}")
    value = %{"code" => code, "main" => "main", "env" => %{}, "binary" => false}
    body = Jason.encode!(%{"value" => value})
    request = {"http://#{host}:#{port}/init", [], ["application/json"], body}
    :httpc.request(:post, request, [], [])
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
    Logger.info("OpenWhisk: Running function on runtime '#{runtime.name}'")
    body = Jason.encode!(%{"value" => args})

    request = {"http://#{runtime.host}:#{runtime.port}/run", [], ["application/json"], body}
    response = :httpc.request(:post, request, [], [])

    case response do
      {:ok, {_, _, payload}} ->
        Logger.info("OpenWhisk: Function executed successfully")
        {:ok, Jason.decode!(payload)}

      {:error, err} ->
        Logger.error("OpenWhisk: Error while running function: #{inspect(err)}")
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
    {:ok, socket} = Application.fetch_env(:worker, :docker_host)

    Logger.info("OpenWhisk: Removing runtime '#{runtime.name}'")
    Nif.cleanup_runtime(runtime.name, socket)

    receive do
      :ok -> {:ok, runtime}
      {:error, err} -> {:error, err}
    end
  end
end

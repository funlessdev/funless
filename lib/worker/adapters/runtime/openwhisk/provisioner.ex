# Copyright 2022 Giuseppe De Palma, Matteo Trentin
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

defmodule Worker.Adapters.Runtime.OpenWhisk.Provisioner do
  @moduledoc """
  Port for runtime manipulation.
  """
  @behaviour Worker.Domain.Ports.Runtime.Provisioner

  alias Worker.Adapters.Runtime.OpenWhisk.Cleaner
  alias Worker.Adapters.Runtime.OpenWhisk.Container
  alias Worker.Adapters.Runtime.OpenWhisk.Nif
  alias Worker.Domain.FunctionStruct
  alias Worker.Domain.ExecutionResource

  require Logger

  @impl true
  def provision(%{__struct__: _s} = f), do: provision(Map.from_struct(f))

  def provision(%{name: _fname, namespace: _ns} = f) do
    {:ok, socket} = Application.fetch_env(:worker, :docker_host)
    {:ok, max_retries} = Application.fetch_env(:worker, :max_runtime_init_retries)
    {:ok, network_name} = Application.fetch_env(:worker, :runtime_network_name)

    # Conversion needed to pass it to the rustler function.
    function = struct(FunctionStruct, f)

    runtime_name = function.name <> "-funless"

    Logger.info("OpenWhisk: Creating runtime for function '#{function.name}'")
    Nif.prepare_runtime(function, runtime_name, network_name, socket)

    receive do
      {:ok, %Container{} = rt} -> init(function, rt, max_retries)
      {:error, err} -> {:error, err}
      err -> {:error, "unexpected response: #{inspect(err)}"}
    end
  end

  @spec init(FunctionStruct.t(), RuntimeStruct.t(), integer()) ::
          {:ok, RuntimeStruct.t()} | {:error, any}
  defp init(_function, runtime, 0 = _retries_left) do
    Logger.error("OpenWhisk: runtime initialization failed.")

    case Cleaner.cleanup(runtime) do
      :ok -> {:error, :max_init_retries_reached}
      {:error, err} -> {:error, {:max_init_retries_reached, {:error, err}}}
    end
  end

  defp init(function, runtime, retries_left) do
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
        case Cleaner.cleanup(runtime) do
          :ok -> reply_from_init({:error, err})
          {:error, cleanup_err} -> reply_from_init({:error, {err, {:error, cleanup_err}}})
        end
    end
  end

  defp send_init(host, port, code) do
    Logger.info("OpenWhisk: sending init request to runtime at #{host}:#{port}")
    value = %{"code" => code, "main" => "main", "env" => %{}, "binary" => false}
    body = Jason.encode!(%{"value" => value})
    request = {"http://#{host}:#{port}/init", [], ["application/json"], body}
    :httpc.request(:post, request, [], [])
  end

  defp reply_from_init({:ok, runtime}) do
    Logger.info("OpenWhisk: Runtime #{runtime.name} initialized")
    {:ok, %ExecutionResource{resource: runtime}}
  end

  defp reply_from_init({:error, err}) do
    Logger.error("OpenWhisk: Runtime initialization failed: #{inspect(err)}")
    {:error, err}
  end

  defp retry_init(function, runtime, retries_left) do
    Logger.warn("OpenWhisk: failed to initialize runtime, retrying...")
    :timer.sleep(10)
    init(function, runtime, retries_left - 1)
  end
end

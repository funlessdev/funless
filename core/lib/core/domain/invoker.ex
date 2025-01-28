# Copyright 2023 Giuseppe De Palma, Matteo Trentin
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

defmodule Core.Domain.Invoker do
  @moduledoc """
  Provides functions to request function invocaiton.
  """
  require Logger

  alias Core.FunctionsMetadata

  alias Core.Domain.{
    Functions,
    Nodes,
    Ports.Commands,
    Ports.DataSinks.Manager,
    Ports.Telemetry.Metrics,
    Scheduler
  }

  alias Data.FunctionMetadata
  alias Data.FunctionStruct
  alias Data.InvokeParams
  alias Data.InvokeResult

  @type invoke_errors ::
          {:error, :not_found} | {:error, :no_workers} | {:error, {:exec_error, any()}}

  @doc """
  Sends an invocation request for the `name` function in the `mod` module,
  specified in the invocation parameters.

  The request is sent with the worker adapter to a worker chosen from the `worker_nodes`, if any.

  ## Parameters
  - ivk_params: a map with module name, function name and a map of args.

  ## Returns
  - {:ok, result} if the invocation was successful, where result is the function result.
  - {:error, :bad_params} if the invocation was requested with invalid invocation parameters.
  - {:error, :not_found} if the function was not found.
  - {:error, :no_workers} if no workers are available.
  - {:error, {:exec_error, msg}} if the worker returned an error.
  """
  @spec invoke(InvokeParams.t()) :: {:ok, InvokeResult.t()} | invoke_errors()
  def invoke(ivk) do
    Logger.info("Invoker: invocation for #{ivk.module}/#{ivk.function} requested")

    with [f] <- Functions.get_by_name_in_mod!(ivk.function, ivk.module),
         {:ok, metadata} <- FunctionsMetadata.get_function_metadata_by_function_id(f.id) do
      func =
        struct(FunctionStruct, %{
          name: ivk.function,
          module: ivk.module,
          hash: f.hash,
          code: nil,
          metadata: struct(FunctionMetadata, %{tag: metadata.tag, capacity: metadata.capacity})
        })

      with {:ok, worker} <- Nodes.worker_nodes() |> Scheduler.select(func, ivk.config, ivk.args) do
        update_concurrent(worker, +1)

        out =
          case invoke_without_code(worker, ivk, f.hash, func.metadata) do
            {:error, :code_not_found, handler} ->
              [%{code: code}] = Functions.get_code_by_name_in_mod!(ivk.function, ivk.module)

              worker
              |> invoke_with_code(handler, ivk, func |> Map.put(:code, code))
              |> save_to_sinks(ivk.module, ivk.function)

            res ->
              save_to_sinks(res, ivk.module, ivk.function)
          end

        update_concurrent(worker, -1)

        out
      end
    else
      [] ->
        {:error, :not_found}

      e ->
        e
    end
  end

  @doc """
  Updates the amount of concurrent functions in the worker metrics.

  ## Parameters
  - worker: the worker of which the metrics will be updated
  - amount: the number that will be summed to the amount of concurrent functions. Can be negative; the final amount has 0 as lower bound.
  """
  @spec update_concurrent(atom(), number()) :: :ok
  def update_concurrent(worker, amount) do
    case Metrics.resources(worker) do
      {:ok, %Data.Worker{} = info} ->
        concurrent =
          case info |> Map.get(:concurrent_functions, 0) do
            nil -> max(0, amount)
            v -> max(0, v + amount)
          end

        Metrics.update(worker, info |> Map.put(:concurrent_functions, concurrent))

      {:error, :not_found} ->
        :ok
    end
  end

  @spec invoke_without_code(atom(), InvokeParams.t(), binary(), FunctionMetadata.t()) ::
          {:ok, InvokeResult.t()} | {:error, :code_not_found, pid()} | invoke_errors()
  def invoke_without_code(worker, ivk, hash, metadata \\ %FunctionMetadata{}) do
    Logger.debug("Invoker: invoking #{ivk.module}/#{ivk.function} without code")
    # send invocation without code
    Commands.send_invoke(worker, ivk.function, ivk.module, hash, ivk.args, metadata)
  end

  @spec invoke_with_code(atom(), pid(), InvokeParams.t(), FunctionStruct.t()) ::
          {:ok, InvokeResult.t()} | {:error, {:exec_error, any()}}
  def invoke_with_code(worker, handler, _, func) do
    Logger.warning("Invoker: function not available in worker, re-invoking with code")
    Commands.send_invoke_with_code(worker, handler, func)
  end

  @spec save_to_sinks({:error, any} | {:ok, InvokeResult.t()}, String.t(), String.t()) ::
          {:error, any} | {:ok, any}
  def save_to_sinks({:ok, ivk_r}, module, name) do
    Logger.info("Invoker: #{module}/#{name} invoked successfully")

    Manager.get_all(module, name)
    |> case do
      {:error, :not_found} ->
        Logger.debug("Invoker: no sinks found for #{module}/#{name}")

        []

      {:ok, children} ->
        Logger.debug("Invoker: saving result to #{length(children)} sinks")

        children
        |> Enum.each(fn sink_pid ->
          GenServer.cast(sink_pid, {:save, ivk_r.result})
        end)
    end

    {:ok, ivk_r.result}
  end

  def save_to_sinks({:error, reason} = reply, module, name) do
    Logger.error("Invoker: failed to invoke #{module}/#{name}: #{inspect(reason)}")
    reply
  end
end

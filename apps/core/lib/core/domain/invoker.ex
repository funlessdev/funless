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

defmodule Core.Domain.Invoker do
  @moduledoc """
  Provides functions to request function invocaiton.
  """
  require Logger
  alias Core.Domain.{Functions, Nodes, Ports.Commands, Ports.DataSinks.Manager, Scheduler}
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
  def invoke(ivk_pars) do
    Logger.info("Invoker: invocation for #{ivk_pars.module}/#{ivk_pars.function} requested")

    # could be {:error, :no_workers}
    with {:ok, worker} <- Nodes.worker_nodes() |> Scheduler.select() do
      case invoke_without_code(worker, ivk_pars) do
        {:error, :code_not_found} ->
          worker
          |> invoke_with_code(ivk_pars)
          |> return_result(ivk_pars.module, ivk_pars.function)

        res ->
          return_result(res, ivk_pars.module, ivk_pars.function)
      end
    end
  end

  @spec invoke_without_code(atom(), InvokeParams.t()) ::
          {:ok, InvokeResult.t()} | {:error, :code_not_found} | invoke_errors()
  def invoke_without_code(worker, ivk) do
    Logger.debug("Invoker: invoking #{ivk.module}/#{ivk.function} without code")

    if Functions.exists_in_mod?(ivk.function, ivk.module) do
      # send invocation without code
      Commands.send_invoke(worker, ivk.function, ivk.module, ivk.args)
    else
      {:error, :not_found}
    end
  end

  @spec invoke_with_code(atom(), InvokeParams.t()) ::
          {:ok, InvokeResult.t()} | {:error, {:exec_error, any()}}
  def invoke_with_code(worker, ivk) do
    Logger.warn("Invoker: function not available in worker, re-invoking with code")

    case Functions.get_code_by_name_in_mod!(ivk.function, ivk.module) do
      [f] ->
        func = %FunctionStruct{
          name: ivk.function,
          module: ivk.module,
          code: f.code
        }

        Commands.send_invoke_with_code(worker, func, ivk.args)

      [] ->
        {:error, :not_found}
    end
  end

  @spec return_result({:error, any} | {:ok, InvokeResult.t()}, String.t(), String.t()) ::
          {:error, any} | {:ok, any}
  def return_result({:ok, ivk_r}, module, name) do
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

  def return_result({:error, reason} = reply, module, name) do
    Logger.error("Invoker: failed to invoke #{module}/#{name}: #{inspect(reason)}")
    reply
  end
end

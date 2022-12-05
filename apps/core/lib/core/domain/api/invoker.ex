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

defmodule Core.Domain.Api.Invoker do
  @moduledoc """
  Provides functions to request function invocaiton.
  """
  require Logger
  alias Core.Domain.Api.Utils
  alias Core.Domain.Nodes
  alias Core.Domain.Ports.Commands
  alias Core.Domain.Ports.FunctionStore
  alias Core.Domain.Scheduler
  alias Data.InvokeParams
  alias Data.InvokeResult

  @type invoke_errors :: {:error, :not_found} | {:error, :no_workers} | {:error, String.t()}

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
  @spec invoke(InvokeParams.t()) ::
          {:ok, InvokeResult.t()} | {:error, :bad_params} | invoke_errors()
  def invoke(%{"function" => f} = raw_params) do
    module = Map.get(raw_params, "module") |> Utils.validate_module()

    ivk_params = %InvokeParams{
      function: f,
      module: module,
      args: Map.get(raw_params, "args", %{})
    }

    Logger.info("API: invocation for #{ivk_params.module}/#{ivk_params.function} requested")

    # could be :no_workers
    worker = Nodes.worker_nodes() |> Scheduler.select()

    res =
      case invoke_without_code(worker, ivk_params) do
        {:error, :code_not_found} -> invoke_with_code(worker, ivk_params)
        res -> res
      end

    handle_result(res, ivk_params.function)
  end

  def invoke(_), do: {:error, :bad_params}

  @spec invoke_without_code(atom(), InvokeParams.t()) ::
          {:ok, InvokeResult.t()} | {:error, :code_not_found} | invoke_errors()
  defp invoke_without_code(:no_workers, _), do: {:error, :no_workers}

  defp invoke_without_code(worker, ivk_params) do
    name = ivk_params.function
    ns = ivk_params.module

    if FunctionStore.exists?(name, ns) do
      # function found in store, send invocation without code
      args = ivk_params.args
      Commands.send_invoke(worker, name, ns, args)
    else
      {:error, :not_found}
    end
  end

  @spec invoke_with_code(atom(), InvokeParams.t()) ::
          {:ok, InvokeResult.t()} | {:error, :not_found} | {:error, any()}
  defp invoke_with_code(worker, ivk_params) do
    Logger.warn("API: function not available in worker, re-invoking with code")

    with {:ok, f} <- FunctionStore.get_function(ivk_params.function, ivk_params.module) do
      Commands.send_invoke_with_code(worker, f, ivk_params.args)
    end
  end

  defp handle_result({:ok, _} = reply, name) do
    Logger.info("API: #{name} invoked successfully")
    reply
  end

  defp handle_result({:error, reason}, name) do
    Logger.error("API: failed to invoke #{name}: #{inspect(reason)}")
    {:error, reason}
  end
end

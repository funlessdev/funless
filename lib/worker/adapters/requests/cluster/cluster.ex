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

defmodule Worker.Adapters.Requests.Cluster do
  @moduledoc """
  Contains functions exposing the Worker API to other processes/nodes in the cluster.
  """
  alias Worker.Domain.CleanupRuntime
  alias Worker.Domain.InvokeFunction
  alias Worker.Domain.ProvisionRuntime

  require Logger

  @doc """
    Creates a runtime for the given `function`, using the underlying Api.prepare(). The result is forwarded to the original sender.

    ## Parameters
      - function: struct containing function information; no specific struct is required, but it should contain all fields defined in Worker.Domain.FunctionStruct
      - from: (sender, ref) couple, generally obtained in GenServer.call(), where this function is normally spawned
  """
  def prepare(function, from) do
    ProvisionRuntime.prepare_runtime(function) |> reply_to_core(from)
  end

  @doc """
    Runs the given `function` using the underlying Api.run_function(), if an associated runtime exists;
    if no runtime is found, creates the required runtime and runs the function.
    Any error encountered by the API calls is forwarded to the sender.

    ## Parameters
      - function: struct containing function information; no specific struct is required, but it should contain all fields defined in Worker.Domain.FunctionStruct
      - args: arguments passed to the function
      - from: (sender, ref) couple, generally obtained in GenServer.call(), where this function is normally spawned
  """
  def invoke(function, args, from) do
    InvokeFunction.invoke(function, args) |> reply_to_core(from)
  end

  @doc """
    Deletes the first runtime wrapping `function`, calling the underlying Api.cleanup(). The result is forwarded to the original sender.

    ## Parameters
      - function: struct containing function information; no specific struct is required, but it should contain all fields defined in Worker.Domain.FunctionStruct
      - from: (sender, ref) couple, generally obtained in GenServer.call(), where this function is normally spawned
  """
  def cleanup(function, from) do
    CleanupRuntime.cleanup(function) |> reply_to_core(from)
  end

  @doc """
    Deletes the all runtimes wrapping `function`, calling the underlying Api.cleanup_all(). The result is forwarded to the original sender.

    ## Parameters
      - function: struct containing function information; no specific struct is required, but it should contain all fields defined in Worker.Domain.FunctionStruct
      - from: (sender, ref) couple, generally obtained in GenServer.call(), where this function is normally spawned
  """
  def cleanup_all(function, from) do
    CleanupRuntime.cleanup_all(function) |> reply_to_core(from)
  end

  @doc false
  defp reply_to_core({:error, msg}, from), do: GenServer.reply(from, {:error, %{"error" => msg}})
  defp reply_to_core({:ok, result}, from), do: GenServer.reply(from, {:ok, result})
end

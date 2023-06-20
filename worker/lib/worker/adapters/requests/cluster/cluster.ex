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

defmodule Worker.Adapters.Requests.Cluster do
  @moduledoc """
  Contains functions exposing the Worker API to other processes/nodes in the cluster.
  """
  alias Worker.Domain.InvokeFunction
  alias Worker.Domain.NodeInfo

  require Logger

  @doc """
    Runs the given `function` using the underlying InvokeFunction.invoke() from the domain.
    It uses the runtime associated with the function from the cache, if it exists.
    If the runtime does not exist, it is provisioned and then run.

    The provisioner might request the runtime from the core
    if no runtime is found, creates the required runtime and runs the function.
    Any error encountered by the API calls is forwarded to the sender.

    ## Parameters
      - function: struct containing function information; no specific struct is required, but it should contain all fields defined in Data.FunctionStruct
      - args: arguments passed to the function
      - from: (sender, ref) couple, generally obtained in GenServer.call(), where this function is normally spawned
  """
  def invoke(function, args, from) do
    InvokeFunction.invoke(function, args) |> reply_to_core(from)
  end

  def set_info(name, tag, from) do
    NodeInfo.set_node_info(name, tag) |> reply_to_core(from)
  end

  def update_info(name, tag, from) do
    NodeInfo.update_node_info(name, tag) |> reply_to_core(from)
  end

  def get_info(from) do
    NodeInfo.get_node_info() |> reply_to_core(from)
  end

  # reply should be either {:ok, result} or {:error, reason}
  defp reply_to_core(reply, from), do: GenServer.reply(from, reply)
end

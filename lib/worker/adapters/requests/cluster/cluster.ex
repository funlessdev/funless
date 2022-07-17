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
defmodule Worker.Adapters.Requests.Cluster do
  @moduledoc """
  Contains functions exposing the Worker API to other processes/nodes in the cluster.
  """
  alias Worker.Domain.Api
  require Logger

  @doc """
    Creates a runtime for the given `function`, using the underlying Api.prepare(). The result is forwarded to the original sender.

    ## Parameters
      - function: struct containing function information; no specific struct is required, but it should contain all fields defined in Worker.Domain.Function
      - from: (sender, ref) couple, generally obtained in GenServer.call(), where this function is normally spawned
  """
  def prepare(function, from) do
    Api.prepare_runtime(function) |> reply_to_core(from)
  end

  @doc """
    Runs the given `function` using the underlying Api.run_function(), if an associated runtime exists;
    if no runtime is found, creates the required runtime and runs the function.
    Any error encountered by the API calls is forwarded to the sender.

    ## Parameters
      - function: struct containing function information; no specific struct is required, but it should contain all fields defined in Worker.Domain.Function
      - args: arguments passed to the function
      - from: (sender, ref) couple, generally obtained in GenServer.call(), where this function is normally spawned
  """
  def invoke(function, args, from) do
    Api.invoke_function(function, args) |> reply_to_core(from)
  end

  @doc """
    Deletes the first runtime wrapping `function`, calling the underlying Api.cleanup(). The result is forwarded to the original sender.

    ## Parameters
      - function: struct containing function information; no specific struct is required, but it should contain all fields defined in Worker.Domain.Function
      - from: (sender, ref) couple, generally obtained in GenServer.call(), where this function is normally spawned
  """
  def cleanup(function, from) do
    Api.cleanup(function) |> reply_to_core(from)
  end

  @doc false
  defp reply_to_core({:error, msg}, from) do
    GenServer.reply(from, %{"error" => msg})
  end

  defp reply_to_core(result, from) do
    GenServer.reply(from, result)
  end
end

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

defmodule Core.Domain.Internal.Invoker do
  @moduledoc false

  require Logger
  alias Core.Domain.Ports.Commands

  @spec invoke(List.t(), Struct.t()) :: {:ok, String.t()} | {:error, any}
  def invoke(nodes, ivk_params) do
    Elixir.Logger.info("Internal Invoker.invoke called")

    Elixir.Logger.info("Internal Invoker.invoke choosing worker...")
    chosen = nodes |> select_worker

    result =
      case chosen do
        :no_workers ->
          Elixir.Logger.info("Internal Invoker.invoke no workers found")
          {:error, message: "No workers availble"}

        _ ->
          Elixir.Logger.info("Internal Invoker.invoke got a worker")
          Commands.send_invocation_command(chosen, ivk_params)
      end

    result
  end

  def select_worker(nodes) do
    Enum.map(nodes, &Atom.to_string(&1))
    |> Enum.zip(0..length(nodes))
    |> Enum.flat_map(&filter_worker(&1))
    |> Core.Nif.Scheduler.select()
    |> extract_worker(nodes)
  end

  defp filter_worker(t) do
    if String.contains?(elem(t, 0), "worker"), do: [%FnWorker{id: elem(t, 1)}], else: []
  end

  # **WARNING**: unidiomatic to use enum.at
  defp extract_worker(%FnWorker{id: i}, nodes), do: Enum.at(nodes, i)
  defp extract_worker(_, _), do: :no_workers
end

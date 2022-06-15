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
  alias Core.Nif.Scheduler

  require Logger
  alias Core.Domain.Ports.Commands

  @spec invoke(List.t(), Struct.t()) :: {:ok, name: String.t()} | {:error, message: String.t()}
  def invoke(worker_nodes, ivk_params) do
    Elixir.Logger.info("Internal Invoker.invoke called")

    Elixir.Logger.info("Internal Invoker.invoke choosing worker...")
    chosen = worker_nodes |> select_worker

    case chosen do
      :no_workers ->
        Elixir.Logger.info("Internal Invoker.invoke no workers found")
        {:error, message: "No workers available"}

      _ ->
        Elixir.Logger.info("Internal Invoker.invoke got a worker")
        Commands.send_invocation_command(chosen, ivk_params)
    end
  end

  def select_worker([]), do: :no_workers

  def select_worker(worker_nodes) do
    Elixir.Logger.info("Internal Invoker.select_worker mapping nodes to FnWorkers")
    fn_workers = Enum.map(0..length(worker_nodes), fn i -> %FnWorker{id: i} end)

    Elixir.Logger.info("Internal Invoker.select_worker calling NIF Scheduler")

    chosen = Scheduler.select(fn_workers)

    Elixir.Logger.info("Internal Invoker.select_worker chosen worker found!")
    extract_worker(chosen, worker_nodes)
  end

  # **WARNING**: unidiomatic to use enum.at
  defp extract_worker(%FnWorker{id: i}, nodes), do: Enum.at(nodes, i)
  defp extract_worker(_, _), do: :no_workers
end

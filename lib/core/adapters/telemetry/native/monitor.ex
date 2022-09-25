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

defmodule Core.Adapters.Telemetry.Native.Monitor do
  @moduledoc """
    Implements GenServer behaviour. Represents a process periodically pulling telemetry information from a single worker.
    This is meant to be run under a supervisor.
  """
  use GenServer, restart: :permanent
  require Logger

  def start_link(node) do
    GenServer.start_link(__MODULE__, node,
      name: {:via, Registry, {Core.Adapters.Telemetry.Native.Registry, "telemetry_#{node}"}}
    )
  end

  @impl true
  def init(node) do
    Logger.info("Telemetry Monitor: monitoring of node #{node} started")
    send(self(), :pull)
    {:ok, node}
  end

  @impl true
  def handle_info(:pull, node) do
    retrieve(node)
    {:noreply, node}
  end

  @doc """
    Pulls telemetry information from the given worker node every 5s.
  """
  def retrieve(worker) do
    with :ok <- find_telemetry_process(worker),
         {:ok, metrics} <- pull_metrics(worker),
         {:ok, _} <- save_metrics_with_timestamp(worker, metrics) do
      Logger.info("Telemetry Monitor: metrics pulled from #{worker}")
    else
      {:error, reason} ->
        Logger.warn("Telemetry Monitor: error pulling metrics #{inspect(reason)}")
    end

    Process.send_after(self(), :pull, 5_000)
  end

  defp find_telemetry_process(worker) do
    :rpc.call(worker, Process, :whereis, [:worker_telemetry])
    |> case do
      nil -> {:error, "Telemetry process not found on #{worker}"}
      {:badrpc, reason} -> {:error, reason}
      _ -> :ok
    end
  end

  @spec pull_metrics(atom()) :: {:ok, map()} | {:error, :not_found}
  defp pull_metrics(worker), do: GenServer.call({:worker_telemetry, worker}, :pull)

  defp save_metrics_with_timestamp(worker, metrics) do
    resources = metrics |> Map.put(:timestamp, DateTime.utc_now())
    GenServer.call(:telemetry_ets_server, {:insert, worker, resources})
  end
end

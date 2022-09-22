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
defmodule Core.Adapters.Telemetry.Native.Collector do
  @moduledoc """
    Implements GenServer behaviour.
    Watches the status of nodes in the cluster and retrieves telemetry information from workers.
    The GenServer state is a map of (worker_node -> pid) couples, where the pid identifies the process pulling the node for telemetry information.
  """
  use GenServer, restart: :permanent
  require Logger

  def start_link(_args) do
    GenServer.start_link(__MODULE__, %{})
  end

  @impl true
  def init(_args) do
    :net_kernel.monitor_nodes(true)
    Logger.info("Telemetry Collector: started")
    {:ok, %{}}
  end

  @impl true
  def terminate(_reason, state) do
    :net_kernel.monitor_nodes(false)

    state
    |> Enum.each(fn {_w, pid} ->
      Process.exit(pid, :parent)
    end)

    Logger.info("Telemetry Collector: terminated")
    :ok
  end

  @impl true
  def handle_info({:nodeup, node}, state) do
    is_worker = node |> Atom.to_string() |> String.contains?("worker")

    if is_worker do
      # TODO: use a DynamicSupervisor to handle addition/removal/restart of child processes
      pid = spawn(__MODULE__, :retrieve_information, [node])

      send(pid, :pull)
      Logger.info("Telemetry Collector: monitoring of node #{node} started")

      new_state = state |> Map.put(node, pid)
      {:noreply, new_state}
    else
      {:noreply, state}
    end
  end

  @impl true
  def handle_info({:nodedown, node}, state) do
    {pid, new_state} = state |> Map.pop(node)

    if is_pid(pid) do
      GenServer.call(:telemetry_ets_server, {:delete, node})
      Process.exit(pid, :disconnected)
      Logger.info("Telemetry Collector: monitoring of node #{node} stopped")
    end

    {:noreply, new_state}
  end

  @doc """
    Pulls telemetry information from the given worker node every 5s.
  """
  def retrieve_information(worker) do
    receive do
      :pull ->
        response = GenServer.call({:worker_telemetry, worker}, :pull)

        case response do
          {:ok, res} ->
            resources = res |> Map.put(:timestamp, DateTime.utc_now())
            GenServer.call(:telemetry_ets_server, {:insert, worker, resources})

          {:error, _} ->
            nil
        end

        Process.send_after(self(), :pull, 5_000)
        retrieve_information(worker)
    end
  end
end

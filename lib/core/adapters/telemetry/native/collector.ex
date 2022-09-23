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
    The GenServer state is just the name of the dynamic supervisor used for handling the various InformationRetriever processes.
  """
  use GenServer, restart: :permanent
  require Logger

  def start_link(dynamic_supervisor) do
    GenServer.start_link(__MODULE__, dynamic_supervisor)
  end

  @impl true
  def init(dynamic_supervisor) do
    :net_kernel.monitor_nodes(true)
    Logger.info("Telemetry Collector: started")
    {:ok, dynamic_supervisor}
  end

  @impl true
  def terminate(_reason, dynamic_supervisor) do
    :net_kernel.monitor_nodes(false)

    Node.list()
    |> Enum.each(fn node ->
      pids =
        Registry.lookup(Core.Adapters.Telemetry.Native.Registry, "telemetry_information_#{node}")

      case pids do
        [{pid, _} | _] -> DynamicSupervisor.terminate_child(dynamic_supervisor, pid)
        _ -> nil
      end
    end)

    Logger.info("Telemetry Collector: terminated")
    :ok
  end

  @impl true
  def handle_info({:nodeup, node}, dynamic_supervisor) do
    is_worker = node |> Atom.to_string() |> String.contains?("worker")

    if is_worker do
      {:ok, _} =
        DynamicSupervisor.start_child(
          dynamic_supervisor,
          {Core.Adapters.Telemetry.Native.InformationRetriever, node}
        )
    end

    {:noreply, dynamic_supervisor}
  end

  @impl true
  def handle_info({:nodedown, node}, dynamic_supervisor) do
    pids =
      Registry.lookup(Core.Adapters.Telemetry.Native.Registry, "telemetry_information_#{node}")

    case pids do
      [{pid, _} | _] ->
        GenServer.call(:telemetry_ets_server, {:delete, node})
        DynamicSupervisor.terminate_child(dynamic_supervisor, pid)
        Logger.info("Telemetry Collector: monitoring of node #{node} stopped")

      _ ->
        nil
    end

    {:noreply, dynamic_supervisor}
  end
end

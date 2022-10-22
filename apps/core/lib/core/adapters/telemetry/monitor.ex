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

defmodule Core.Adapters.Telemetry.Monitor do
  @moduledoc """
    Implements GenServer behaviour.
    Watches the status of nodes in the cluster and retrieves telemetry information from workers.
    The GenServer state is just the name of the dynamic supervisor used for handling the various Telemetry.Collector processes.

    When a worker node comes online, the Monitor starts a Telemetry.Collector process for that node.
    When a worker node goes offline, the Monitor stops the corresponding Telemetry.Collector process.
  """
  use GenServer, restart: :permanent

  alias Core.Adapters.Telemetry.MetricsServer
  require Logger

  def start_link(dynamic_supervisor) do
    GenServer.start_link(__MODULE__, dynamic_supervisor)
  end

  @impl true
  def init(dynamic_supervisor) do
    _ = :net_kernel.monitor_nodes(true)
    Logger.info("Worker Nodes Monitor: started")
    {:ok, dynamic_supervisor}
  end

  @impl true
  def terminate(_reason, dynamic_supervisor) do
    _ = :net_kernel.monitor_nodes(false)

    Node.list()
    |> Enum.each(fn node -> terminate_child(node, dynamic_supervisor) end)

    Logger.info("Worker Nodes Monitor: terminated")
    :ok
  end

  defp terminate_child(node, dynamic_supervisor) do
    Registry.lookup(Core.Adapters.Telemetry.Registry, "telemetry_#{node}")
    |> case do
      [{pid, _} | _] -> DynamicSupervisor.terminate_child(dynamic_supervisor, pid)
      _ -> nil
    end
  end

  @impl true
  def handle_info({:nodeup, node}, dynamic_supervisor) do
    if is_worker(node) do
      _ =
        DynamicSupervisor.start_child(
          dynamic_supervisor,
          {Core.Adapters.Telemetry.Collector, node}
        )

      Logger.info("Worker Nodes Monitor: monitoring of #{node} started")
    end

    {:noreply, dynamic_supervisor}
  end

  @impl true
  def handle_info({:nodedown, node}, dynamic_supervisor) do
    Registry.lookup(Core.Adapters.Telemetry.Registry, "telemetry_#{node}")
    |> case do
      [{pid, _} | _] -> clear_node(node, pid, dynamic_supervisor)
      _ -> nil
    end

    {:noreply, dynamic_supervisor}
  end

  defp clear_node(node, pid, sup) do
    MetricsServer.delete(node)
    DynamicSupervisor.terminate_child(sup, pid)
    Logger.info("Worker Nodes Monitor: monitoring of #{node} stopped")
  end

  defp is_worker(node) do
    node |> Atom.to_string() |> String.contains?("worker")
  end
end

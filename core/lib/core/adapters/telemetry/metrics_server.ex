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

defmodule Core.Adapters.Telemetry.MetricsServer do
  @moduledoc """
  The cache for the metrics of each worker node. Implemented using an ETS table.

  Everytime the metrics of a worker node are retrieved, they are inserted here overwriting the previous value.
  This way the scheduler has a fast access to the most recent metrics.
  """
  use GenServer, restart: :permanent
  require Logger

  @metrics_ets_server :metrics_ets_server
  @ets_table :worker_resources

  @spec get(atom()) :: Data.Worker.t() | :not_found
  def get(worker_node) do
    case :ets.lookup(@ets_table, worker_node) do
      [{^worker_node, metrics}] -> metrics
      [] -> :not_found
    end
  end

  @spec insert(atom(), Data.Worker.t()) :: :ok
  def insert(worker_node, resources) do
    GenServer.call(@metrics_ets_server, {:insert, worker_node, resources})
  end

  @spec delete(atom()) :: :ok
  def delete(worker_node) do
    GenServer.call(@metrics_ets_server, {:delete, worker_node})
  end

  # Genserver callbacks
  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: @metrics_ets_server)
  end

  @impl true
  def init(_args) do
    table = :ets.new(@ets_table, [:set, :named_table, :protected])
    Logger.info("Telemetry ETS Server: started")
    {:ok, table}
  end

  @impl true
  def handle_call({:insert, worker_node, resources}, _from, table) do
    :ets.insert(table, {worker_node, resources})
    {:reply, {:ok, {worker_node, resources}}, table}
  end

  @impl true
  def handle_call({:delete, worker_node}, _from, table) do
    :ets.delete(table, worker_node)
    Logger.info("Telemetry ETS Server: deleted #{worker_node}")
    {:reply, {:ok, worker_node}, table}
  end
end

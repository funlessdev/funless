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

defmodule Core.Adapters.Connectors.ManagerStore do
  @moduledoc """
  The cache for Event Connectors PIDs.
  When a function is connected to an event, the pid for the corresponding Event Connector is stored here, using `module/function` as key.
  When a function is deleted or disconnected from its events, the entry is removed.
  """
  use GenServer, restart: :permanent
  require Logger

  @connectors_ets_server :connectors_ets_server
  @ets_table :connectors_manager_functions

  @spec get(String.t(), String.t()) :: [pid()] | :not_found
  def get(function, module) do
    key = module <> "/" <> function

    case :ets.lookup(@ets_table, key) do
      [{^key, pids}] -> pids
      [] -> :not_found
    end
  end

  @spec insert(String.t(), String.t(), pid()) :: {:ok, {String.t(), pid}}
  def insert(function, module, pid) do
    key = module <> "/" <> function
    GenServer.call(@connectors_ets_server, {:insert, key, pid})
  end

  @spec delete(String.t(), String.t()) :: {:ok, String.t()}
  def delete(function, module) do
    key = module <> "/" <> function
    GenServer.call(@connectors_ets_server, {:delete, key})
  end

  # Genserver callbacks
  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: @connectors_ets_server)
  end

  @impl true
  def init(_args) do
    table = :ets.new(@ets_table, [:set, :named_table, :protected])
    Logger.info("Connectors ETS Server: started")
    {:ok, table}
  end

  @impl true
  def handle_call({:insert, key, pid}, _from, table) do
    :ets.insert(table, {key, pid})
    {:reply, {:ok, {key, pid}}, table}
  end

  @impl true
  def handle_call({:delete, key}, _from, table) do
    :ets.delete(table, key)
    Logger.info("Connectors ETS Server: deleted #{key}")
    {:reply, {:ok, key}, table}
  end
end

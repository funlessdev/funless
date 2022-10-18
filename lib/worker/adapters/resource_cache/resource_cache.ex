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

defmodule Worker.Adapters.ResourceCache do
  @moduledoc """
    Implements the ResourceCache behaviour.
    It uses a GenServer process having exclusive writing rights on an underlying ETS table.

    The {function_name, namespace} couples are the keys that point to ExecutionResources.
  """
  @behaviour Worker.Domain.Ports.ResourceCache

  use GenServer, restart: :permanent
  require Logger

  @resource_cache_server :resource_cache_server
  @resource_cache_table :resource_cache

  @impl true
  def get(function_name, namespace) do
    case :ets.lookup(@resource_cache_table, {function_name, namespace}) do
      [{{^function_name, ^namespace}, runtime}] -> runtime
      _ -> :resource_not_found
    end
  end

  @impl true
  def insert(function_name, namespace, resource) do
    GenServer.call(@resource_cache_server, {:insert, function_name, namespace, resource})
  end

  @impl true
  def delete(function_name, namespace) do
    GenServer.call(@resource_cache_server, {:delete, function_name, namespace})
  end

  # GenServer callbacks
  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: @resource_cache_server)
  end

  @impl true
  def init(_args) do
    table = :ets.new(@resource_cache_table, [:set, :named_table, :protected])
    Logger.info("Resource Cache: started")
    {:ok, table}
  end

  @impl true
  def handle_call({:insert, function_name, namespace, runtime}, _from, table) do
    :ets.insert(table, {{function_name, namespace}, runtime})
    Logger.info("Resource Cache: added resource for #{function_name} in #{namespace}")
    {:reply, :ok, table}
  end

  @impl true
  def handle_call({:delete, function_name, namespace}, _from, table) do
    :ets.delete(table, {function_name, namespace})
    Logger.info("Resource Cache: deleted resource of #{function_name} in #{namespace}")
    {:reply, :ok, table}
  end
end

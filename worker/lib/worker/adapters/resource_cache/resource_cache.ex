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

defmodule Worker.Adapters.ResourceCache do
  @moduledoc """
    Implements the ResourceCache behaviour.
    It uses a GenServer process having exclusive writing rights on an underlying ETS table.

    The {function_name, module} couples are the keys that point to ExecutionResources.
  """
  @behaviour Worker.Domain.Ports.ResourceCache

  use GenServer, restart: :permanent
  require Logger

  @resource_cache_server :resource_cache_server
  @resource_cache_table :resource_cache

  @doc """
  Retrieve a resource from the cache, associated with a function name and a module.
  Checks if the retrieved resource matches the given hash; if it doesn't, it's ignored.

  ## Parameters
  - `function_name`: the name of the function
  - `module`: the module of the function
  - `hash`: the hash of the non-compiled code of the function.

  ## Returns
  - `resource` if the resource is found;
  - `:resource_not_found` if the resource is not found.
  """
  @impl true
  def get(function_name, module, hash) do
    case :ets.lookup(@resource_cache_table, {function_name, module}) do
      [{{^function_name, ^module}, {^hash, resource}}] -> resource
      _ -> :resource_not_found
    end
  end

  @doc """
  Store a resource in the cache, associated with a function name and a module.

  ## Parameters
  - `function_name`: the name of the function
  - `module`: the module of the function
  - `resource`: the resource to store

  ## Returns
  - `:ok`
  """
  @impl true
  def insert(function_name, module, hash, resource) do
    GenServer.call(@resource_cache_server, {:insert, function_name, module, hash, resource})
  end

  @doc """
  Remove a resource from the cache, associated with a function name and a module.

  ## Parameters
  - `function_name`: the name of the function
  - `module`: the module of the function

  ## Returns
  - `:ok`
  """
  @impl true
  def delete(function_name, module, hash) do
    GenServer.call(@resource_cache_server, {:delete, function_name, module, hash})
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
  def handle_call({:insert, function_name, module, hash, runtime}, _from, table) do
    :ets.insert(table, {{function_name, module}, {hash, runtime}})
    {:reply, :ok, table}
  end

  @impl true
  def handle_call({:delete, function_name, module, hash}, _from, table) do
    :ets.match_delete(table, {{function_name, module}, {hash, :_}})
    {:reply, :ok, table}
  end
end

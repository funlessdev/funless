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

defmodule Worker.Adapters.RuntimeTracker.ETS.WriteServer do
  @moduledoc """
    Implements GenServer behaviour; represents a process having exclusive writing rights on an underlying ETS table.

    The {function_name, runtime} couples are inserted or deleted by using GenServer.call() on this process; the table name is currently hardcoded to
    :functions_runtimes.
  """
  use GenServer, restart: :permanent
  require Logger

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: :write_server)
  end

  @impl true
  def init(_args) do
    table = :ets.new(:functions_runtimes, [:bag, :named_table, :protected])
    Logger.info("Function Storage Server: started")
    {:ok, table}
  end

  @impl true
  def handle_call({:insert, function_name, runtime}, _from, table) do
    :ets.insert(table, {function_name, runtime})
    Logger.info("Function Storage Server: added #{function_name} => #{runtime.name}")
    {:reply, {:ok, {function_name, runtime}}, table}
  end

  @impl true
  def handle_call({:delete, function_name, runtime}, _from, table) do
    :ets.delete_object(table, {function_name, runtime})
    Logger.info("Function Storage Server: deleted #{function_name} => #{runtime.name}")
    {:reply, {:ok, {function_name, runtime}}, table}
  end
end

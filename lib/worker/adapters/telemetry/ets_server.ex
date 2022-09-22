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
defmodule Worker.Adapters.Telemetry.EtsServer do
  @moduledoc """
    Implements GenServer behaviour; represents a process having exclusive writing rights on an underlying ETS table.

    The {key, value} couples are inserted or deleted by using GenServer.call() on this process; the table name is currently hardcoded to
    :worker_telemetry_ets.
  """
  use GenServer, restart: :permanent
  require Logger

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: :telemetry_ets_server)
  end

  @impl true
  def init(_args) do
    table = :ets.new(:worker_telemetry_ets, [:set, :named_table, :protected])
    Logger.info("Telemetry ETS Server: started")
    {:ok, table}
  end

  @impl true
  def handle_call({:insert, key, value}, _from, table) do
    :ets.insert(table, {key, value})
    {:reply, {:ok, {key, value}}, table}
  end

  @impl true
  def handle_call({:delete, key}, _from, table) do
    :ets.delete(table, key)
    {:reply, {:ok, key}, table}
  end
end

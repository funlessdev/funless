# Copyright 2022 Giuseppe De Palma, Matteo Trentin
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

defmodule Core.Adapters.DataSinks.MongoDB do
  @moduledoc """
  Postgres Data Sink Adapter. It implements the Supervisor behaviour that handles an Ecto repo connected to the given Postgres database.
  """
  use GenServer

  require Logger

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts)
  end

  @impl true
  def init(%{"mongo_url" => url, "collection" => col} = opts) do
    Process.flag(:trap_exit, true)

    Logger.info("MongoDB Sink: init with #{inspect(opts)}")
    # Starts an unpooled connection
    {:ok, conn_pid} = Mongo.start_link(url: url)
    {:ok, %{mongodb_pid: conn_pid, collection: col}}
  end

  def init(_), do: {:stop, "MongoDB Sink: init failed"}

  @impl true
  def handle_cast({:save, result}, %{mongodb_pid: pid, collection: col} = state) do
    Logger.info("MongoDB Sink: received #{inspect(result)}... saving it to #{col}")

    Mongo.insert_one(pid, col, result)
    {:noreply, state}
  end
end

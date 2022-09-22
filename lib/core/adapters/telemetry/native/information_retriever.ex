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

defmodule Core.Adapters.Telemetry.Native.InformationRetriever do
  @moduledoc """
    Implements GenServer behaviour. Represents a process periodically pulling telemetry information from a single worker.
    This is meant to be run under a supervisor.
  """
  use GenServer, restart: :permanent
  require Logger

  def start_link(node) do
    GenServer.start_link(__MODULE__, node,
      name:
        {:via, Registry,
         {Core.Adapters.Telemetry.Native.Registry, "telemetry_information_#{node}"}}
    )
  end

  @impl true
  def init(node) do
    Logger.info("Telemetry Information Retriever: monitoring of node #{node} started")
    send(self(), :pull)
    {:ok, node}
  end

  @impl true
  def handle_info(:pull, node) do
    retrieve_information(node)
    {:noreply, node}
  end

  @doc """
    Pulls telemetry information from the given worker node every 5s.
  """
  def retrieve_information(worker) do
    if :rpc.call(worker, Process, :whereis, [:worker_telemetry]) != nil do
      response = GenServer.call({:worker_telemetry, worker}, :pull)

      case response do
        {:ok, res} ->
          resources = res |> Map.put(:timestamp, DateTime.utc_now())
          GenServer.call(:telemetry_ets_server, {:insert, worker, resources})

        {:error, _} ->
          nil
      end
    else
      Logger.warn(
        "Telemetry Information Retriever: no worker_telemetry process found for #{worker}"
      )
    end

    Process.send_after(self(), :pull, 5_000)
  end
end

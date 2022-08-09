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

defmodule Worker.Application do
  @moduledoc false
  alias Worker.Adapters
  use Application
  require Logger

  @impl true
  def start(_type, _args) do
    children = [
      {Adapters.RuntimeTracker.ETS.WriteServer, []},
      {Adapters.Requests.Cluster.Server, []}
    ]

    Supervisor.start_link(children, strategy: :rest_for_one)
  end

  @impl true
  def start_phase(:core_connect, _phase_type, :test), do: :ok

  @impl true
  def start_phase(:core_connect, _phase_type, _) do
    case Application.fetch_env(:worker, :core) do
      {:ok, value} -> connect_to_core(value)
      :error -> Logger.warn("No Core node name given. Worker is not connected!")
    end

    :ok
  end

  defp connect_to_core(core_node) do
    res = String.to_atom(core_node) |> Node.connect()

    case res do
      true -> Logger.info("Connected to Core node #{core_node}")
      _ -> Logger.warn("Could not connect to Core node #{core_node}")
    end
  end
end

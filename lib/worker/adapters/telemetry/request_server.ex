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

defmodule Worker.Adapters.Telemetry.RequestServer do
  @moduledoc """
    Implements GenServer behaviour; the actor receives telemetry :pull requests, and returns the contents of the relative ETS table.
  """
  use GenServer, restart: :permanent
  require Logger

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: :worker_telemetry)
  end

  @impl true
  def init(_args) do
    # Process.flag(:trap_exit, true)
    Logger.info("Telemetry Request Server: started")
    {:ok, nil}
  end

  @impl true
  def handle_call(:pull, _from, _state) do
    reply =
      :ets.lookup(:worker_telemetry_ets, :resources)
      |> Enum.map(fn {_k, v} -> v end)
      |> case do
        [r | _] -> {:ok, r}
        [] -> {:error, :not_found}
      end

    {:reply, reply, nil}
  end
end

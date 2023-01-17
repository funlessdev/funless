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

defmodule Core.Adapters.DataSinks.Supervisor do
  @moduledoc """
  Supervisor for the DataSinks Manager ETS server and the DynamicSupervisor used to handle data sinks.
  """
  use Supervisor
  require Logger

  def start_link(args) do
    Supervisor.start_link(__MODULE__, args, name: __MODULE__)
  end

  @impl true
  def init(_args) do
    Logger.info("Data Sink Supervisor: started")

    children = [
      {Registry, keys: :unique, name: Core.Adapters.DataSinks.Registry},
      {DynamicSupervisor,
       strategy: :one_for_one,
       max_restarts: 5,
       max_seconds: 5,
       name: Core.Adapters.DataSinks.DynamicSupervisor}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end

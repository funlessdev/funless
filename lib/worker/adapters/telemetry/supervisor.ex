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

defmodule Worker.Adapters.Telemetry.Supervisor do
  @moduledoc """
    Implements Supervisor behaviour; starts the telemetry measurements, the ETS Server and the Request Server.
  """
  use Supervisor
  alias Worker.Adapters.Telemetry.Handler

  require Logger

  def start_link(args) do
    Supervisor.start_link(__MODULE__, args, name: __MODULE__)
  end

  @impl true
  def init(_args) do
    # Process.flag(:trap_exit, true)
    Logger.info("Telemetry supervisor: started")

    children = [
      {:telemetry_poller, measurements: periodic_measurements(), period: 2_500},
      {Worker.Adapters.Telemetry.EtsServer, []},
      {Worker.Adapters.Telemetry.RequestServer, []}
    ]

    Handler.setup()
    Supervisor.init(children, strategy: :one_for_one)
  end

  defp periodic_measurements do
    [
      {Worker.Adapters.Telemetry.Resources, :measure_resources, []}
    ]
  end
end

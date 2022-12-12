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

defmodule Core.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Core.Supervisor]
    Supervisor.start_link(children(), opts)
  end

  defp children do
    topologies = Application.fetch_env!(:core, :topologies)

    [
      ## CoreWeb Children
      CoreWeb.PromEx,
      # Start the Telemetry supervisor
      CoreWeb.Telemetry,
      # Start the Endpoint (http/https)
      CoreWeb.Endpoint,
      # Start a worker by calling: CoreWeb.Worker.start_link(arg)
      # {CoreWeb.Worker, arg}
      ## Core Children
      Core.Repo,
      {Cluster.Supervisor, [topologies, [name: Core.ClusterSupervisor]]},
      {Core.Adapters.Telemetry.Supervisor, []},
      {Core.Adapters.Connectors.Supervisor, []}
    ]
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    CoreWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end

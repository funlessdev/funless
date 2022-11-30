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

  alias Core.Domain.Nodes
  alias Core.Domain.Ports.FunctionStore

  use Application

  @impl true
  def start(_type, _args) do
    topologies = Application.fetch_env!(:core, :topologies)

    children = [
      ## CoreWeb Children
      CoreWeb.PromEx,
      # Start the Telemetry supervisor
      CoreWeb.Telemetry,
      # Start the Ecto repository
      Core.Repo,
      # Start the Endpoint (http/https)
      CoreWeb.Endpoint,
      # Start a worker by calling: CoreWeb.Worker.start_link(arg)
      # {CoreWeb.Worker, arg}

      ## Core Children
      {Cluster.Supervisor, [topologies, [name: Core.ClusterSupervisor]]},
      {Core.Adapters.Telemetry.Supervisor, []}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Core.Supervisor]
    Supervisor.start_link(children, opts)
  end

  @impl true
  def start_phase(:init_db, _phase_type, :test) do
    :ok
  end

  @impl true
  def start_phase(:init_db, _phase_type, _env) do
    res =
      Nodes.core_nodes()
      |> FunctionStore.init_database()

    case res do
      :ok -> :ok
      {:error, {:aborted, {:already_exists, _}}} -> :ok
      err -> err
    end
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    CoreWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end

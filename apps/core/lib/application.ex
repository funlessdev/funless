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
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  alias Core.Domain.Nodes
  alias Core.Domain.Ports.FunctionStore

  use Application

  @impl true
  def start(_type, _args) do
    topologies = Application.fetch_env!(:libcluster, :topologies)

    children = [
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

  def libcluster_config() do
    libcluster_config = Application.fetch_env!(:libcluster, :deploy_type)

    strat =
      case libcluster_config do
        "kubernetes" ->
          [
            # The selected clustering strategy. Required.
            strategy: Cluster.Strategy.Kubernetes,
            config: [
              kubernetes_ip_lookup_mode: :pods,
              kubernetes_node_basename: "worker",
              kubernetes_selector: "app=fl-worker",
              kubernetes_namespace: "fl"
            ]
          ]

        "gossip" ->
          [
            # The selected clustering strategy. Required.
            strategy: Cluster.Strategy.Gossip,
            config: [
              port: String.to_integer(Application.fetch_env!(:libcluster, :libcluster_port))
            ]
          ]
      end

    [topologies: [funless_core: strat]]
  end
end

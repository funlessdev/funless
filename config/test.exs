# Copyright 2023 Giuseppe De Palma, Matteo Trentin
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

import Config

# Print only errors during test, add :console to print logs
config :logger, level: :warn, backends: []

# --- Core Configs ---
config :core, Core.Domain.Ports.Commands, adapter: Core.Commands.Mock
config :core, Core.Domain.Ports.Cluster, adapter: Core.Cluster.Mock
config :core, Core.Domain.Ports.Telemetry.Metrics, adapter: Core.Telemetry.Metrics.Mock
config :core, Core.Domain.Ports.Connectors.Manager, adapter: Core.Connectors.Manager.Mock
config :core, Core.Domain.Ports.DataSinks.Manager, adapter: Core.DataSinks.Manager.Mock

# Configure your database

# The MIX_TEST_PARTITION environment variable can be used
# to provide built-in test partitioning in CI environment.
# Run `mix help test` for more information.
config :core, Core.Repo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  database: "core_test#{System.get_env("MIX_TEST_PARTITION")}",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: 10

config :core, Core.SubjectsRepo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  database: "subjects_test#{System.get_env("MIX_TEST_PARTITION")}",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: 10

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :core, CoreWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "qUx9qUZ2rw23iFpaaPtFTwDhcULosXXK5l/wAv3o4MSHS0WYWNFC7D4v6m2e1pX7",
  server: false

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime

# --- Worker Configs ---
config :worker, Worker.Domain.Ports.ResourceCache, adapter: Worker.ResourceCache.Mock
config :worker, Worker.Domain.Ports.Runtime.Provisioner, adapter: Worker.Provisioner.Mock
config :worker, Worker.Domain.Ports.Runtime.Runner, adapter: Worker.Runner.Mock
config :worker, Worker.Domain.Ports.Runtime.Cleaner, adapter: Worker.Cleaner.Mock

# --- Libcluster Configs ---
config :core,
  topologies: [
    funless_test: [
      # The selected clustering strategy. Required.
      strategy: Cluster.Strategy.Gossip,
      config: [
        port: String.to_integer(System.get_env("LIBCLUSTER_PORT") || "45892")
      ]
    ]
  ]

config :worker,
  topologies: [
    funless_test: [
      # The selected clustering strategy. Required.
      strategy: Cluster.Strategy.Gossip,
      config: [
        port: String.to_integer(System.get_env("LIBCLUSTER_PORT") || "45893")
      ]
    ]
  ]

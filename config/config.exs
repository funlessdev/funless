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

import Config

config :core, Core.Domain.Ports.Commands, adapter: Core.Adapters.Commands.Worker
config :core, Core.Domain.Ports.Cluster, adapter: Core.Adapters.Cluster
config :core, Core.Domain.Ports.FunctionStorage, adapter: Core.Adapters.FunctionStorage.Mnesia
config :core, Core.Domain.Ports.Telemetry.Api, adapter: Core.Adapters.Telemetry.Native.Api

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id, :file, :line]

config :libcluster,
  topologies: [
    funless: [
      # The selected clustering strategy. Required.
      strategy: Cluster.Strategy.Gossip
    ]
  ]

config :core_web,
  generators: [context_app: :core]

# Configures the endpoint
config :core_web, CoreWeb.Endpoint,
  url: [host: "localhost"],
  render_errors: [view: CoreWeb.ErrorView, accepts: ~w(json), layout: false],
  pubsub_server: Core.PubSub,
  live_view: [signing_salt: "sRzweIOe"]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"

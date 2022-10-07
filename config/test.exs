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

config :core, Core.Domain.Ports.Commands, adapter: Core.Commands.Mock
config :core, Core.Domain.Ports.Cluster, adapter: Core.Cluster.Mock
config :core, Core.Domain.Ports.FunctionStore, adapter: Core.FunctionStore.Mock
config :core, Core.Domain.Ports.Telemetry.Api, adapter: Core.Telemetry.Api.Mock

# Print only errors during test
config :logger, level: :warn

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :core_web, CoreWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "qUx9qUZ2rw23iFpaaPtFTwDhcULosXXK5l/wAv3o4MSHS0WYWNFC7D4v6m2e1pX7",
  server: false

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime

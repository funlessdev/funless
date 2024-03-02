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

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id, :file, :line]

# --- Worker Configs ---
config :worker, Worker.Domain.Ports.WaitForCode, adapter: Worker.Adapters.WaitForCode

config :worker, Worker.Domain.Ports.Runtime.Provisioner,
  adapter: Worker.Adapters.Runtime.Wasm.Provisioner

config :worker, Worker.Domain.Ports.Runtime.Runner, adapter: Worker.Adapters.Runtime.Wasm.Runner
config :worker, Worker.Domain.Ports.Runtime.Cleaner, adapter: Worker.Adapters.Runtime.Wasm.Cleaner

config :worker, Worker.Domain.Ports.Runtime.Supervisor,
  adapter: Worker.Adapters.Runtime.Wasm.Supervisor

config :worker, Worker.Domain.Ports.ResourceCache, adapter: Worker.Adapters.ResourceCache

config :worker, Worker.Domain.Ports.ResourceCache.Supervisor,
  adapter: Worker.Adapters.ResourceCache.Supervisor

config :worker, Worker.Domain.Ports.RawResourceStorage,
  adapter: Worker.Adapters.RawResourceStorage

config :worker, Worker.Domain.Ports.NodeInfoStorage,
  adapter: Worker.Adapters.NodeInfoStorage.LocalInfoStorage

config :worker, Worker.Domain.Ports.NodeInfoStorage.Supervisor,
  adapter: Worker.Adapters.NodeInfoStorage.Supervisor

config :worker, Worker.Adapters.NodeInfoStorage.LocalInfoStorage, path: "/tmp/node_info"
config :worker, Worker.Adapters.RawResourceStorage, prefix: "/tmp/funless/"

config :os_mon,
  start_cpu_sup: true,
  start_memsup: true,
  start_disksup: false,
  start_os_sup: false,
  memsup_system_only: true

config :worker, Worker.PromEx,
  disabled: false,
  manual_metrics_start_delay: :no_delay,
  drop_metrics_groups: [],
  grafana: :disabled,
  metrics_server: [
    port: 4021,
    # This is an optional setting and will default to `"/metrics"`
    path: "/metrics",
    # This is an optional setting and will default to `:http`
    protocol: :http,
    # This is an optional setting and will default to `5`
    pool_size: 5,
    # This is an optional setting and will default to `[]`
    cowboy_opts: [],
    # This is an optional and will default to `:none`
    auth_strategy: :none
  ]

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"

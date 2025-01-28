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
config :logger, level: :warning, backends: []

# --- Worker Configs ---
config :worker, Worker.Domain.Ports.ResourceCache, adapter: Worker.ResourceCache.Mock
config :worker, Worker.Domain.Ports.RawResourceStorage, adapter: Worker.RawResourceStorage.Mock
config :worker, Worker.Domain.Ports.Runtime.Provisioner, adapter: Worker.Provisioner.Mock
config :worker, Worker.Domain.Ports.Runtime.Runner, adapter: Worker.Runner.Mock
config :worker, Worker.Domain.Ports.Runtime.Cleaner, adapter: Worker.Cleaner.Mock
config :worker, Worker.Domain.Ports.NodeInfoStorage, adapter: Worker.NodeInfoStorage.Mock

config :worker, Worker.Adapters.RawResourceStorage, prefix: "/tmp/funless/test/"

# --- Libcluster Configs ---
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

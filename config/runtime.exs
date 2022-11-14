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

config :worker, docker_host: Worker.Application.docker_socket()
config :worker, max_runtime_init_retries: 20
config :worker, runtime_network_name: System.get_env("RUNTIME_NETWORK", "bridge")

case System.get_env("DEPLOY_ENV") do
  "kubernetes" ->
    config :libcluster,
      topologies: [
        funless_worker: [
          # The selected clustering strategy. Required.
          strategy: Cluster.Strategy.Kubernetes,
          config: [
            kubernetes_ip_lookup_mode: :pods,
            # port: String.to_integer(System.get_env("FL_LIBCLUSTER_PORT") || "45892")
            # application_name: "worker",
            kubernetes_node_basename: "core",
            kubernetes_selector: "app=fl-core",
            kubernetes_namespace: "fl"
          ]
        ]
      ]

  _ ->
    config :libcluster,
      topologies: [
        funless_worker: [
          # The selected clustering strategy. Required.
          strategy: Cluster.Strategy.Gossip,
          config: [
            port: String.to_integer(System.get_env("FL_LIBCLUSTER_PORT") || "45892")
          ]
        ]
      ]
end

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

config :iex, default_prompt: ">>>"

# config/runtime.exs is executed for all environments, including
# during releases. It is executed after compilation and before the
# system starts, so it is typically used to load production configuration
# and secrets from environment variables or elsewhere. Do not define
# any compile-time configuration in here, as it won't be applied.
# The block below contains prod specific runtime configuration.
if config_env() == :prod do
  # The secret key base is used to sign/encrypt cookies and other secrets.
  # A default value is used in config/dev.exs and config/test.exs but you
  # want to use a different value for prod and you most likely don't want
  # to check this value into version control, so we use an environment
  # variable instead.
  secret_key_base =
    System.get_env("SECRET_KEY_BASE") ||
      raise """
      environment variable SECRET_KEY_BASE is missing.
      You can generate one by calling: mix phx.gen.secret
      """

  config :core_web, CoreWeb.Endpoint,
    http: [
      # Enable IPv6 and bind on all interfaces.
      # Set it to  {0, 0, 0, 0, 0, 0, 0, 1} for local network only access.
      ip: {0, 0, 0, 0, 0, 0, 0, 0},
      port: String.to_integer(System.get_env("PORT") || "4000")
    ],
    secret_key_base: secret_key_base

  # ## Using releases
  #
  # If you are doing OTP releases, you need to instruct Phoenix
  # to start each relevant endpoint:
  #
  config :core_web, CoreWeb.Endpoint, server: true
  #
  # Then you can assemble a release by calling `mix release`.
  # See `mix help release` for more information.

  # configuration for the {LoggerFileBackend, :info_log} backend
  config :logger, :info_log,
    path: "/tmp/funless/fl-core.log",
    level: :info
end

case System.get_env("DEPLOY_ENV") do
  "kubernetes" ->
    config :libcluster,
      topologies: [
        funless_core: [
          # The selected clustering strategy. Required.
          strategy: Cluster.Strategy.Kubernetes,
          config: [
            kubernetes_ip_lookup_mode: :pods,
            kubernetes_node_basename: "worker",
            kubernetes_selector: "app=fl-worker",
            kubernetes_namespace: "fl"
          ]
        ]
      ]

  _ ->
    config :libcluster,
      topologies: [
        funless_core: [
          # The selected clustering strategy. Required.
          strategy: Cluster.Strategy.Gossip,
          config: [
            port: String.to_integer(System.get_env("LIBCLUSTER_PORT") || "45892")
          ]
        ]
      ]
end

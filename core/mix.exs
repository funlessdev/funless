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

defmodule Core.MixProject do
  use Mix.Project

  def project do
    [
      app: :core,
      version: "0.8.0",
      elixir: "~> 1.14",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      dialyzer: [
        plt_file: {:no_warn, "priv/plts/dialyzer.plt"},
        plt_add_apps: [:ex_unit, :mix]
      ],
      compilers: Mix.compilers(),
      aliases: aliases(),
      deps: deps(),
      preferred_cli_env: [itest: :test]
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {Core.Application, []},
      extra_applications: [:logger, :runtime_tools, :os_mon]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      {:data, path: "../data"},
      # prod deps
      {:phoenix, "~> 1.6.15"},
      {:phoenix_ecto, "~> 4.4"},
      {:phoenix_live_dashboard, "~> 0.6"},
      {:ecto_sql, "~> 3.6"},
      {:postgrex, ">= 0.0.0"},
      {:jason, "~> 1.3"},
      {:libcluster, "~> 3.3"},
      {:logger_file_backend, "~> 0.0.13"},
      {:telemetry_metrics, "~> 0.6"},
      {:telemetry_poller, "~> 1.0"},
      {:plug_cowboy, "~> 2.5.2"},
      {:prom_ex, "~> 1.8"},
      {:emqtt, github: "emqx/emqtt", tag: "1.6.1", system_env: [{"BUILD_WITHOUT_QUIC", "1"}]},
      {:ecto_psql_extras, "~> 0.7"},
      {:yaml_elixir, "~> 2.9.0"},
      {:cowlib, "~> 2.11.0", override: true},
      # dev deps
      {:mox, "~> 1.0", only: :test},
      {:dialyxir, "~> 1.0", only: [:dev], runtime: false},
      {:credo, "~> 1.6", only: [:dev, :test], runtime: false}
    ]
  end

  # Aliases are shortcuts or tasks specific to the current project.
  #
  # See the documentation for `Mix` for more info on aliases.
  defp aliases do
    [
      setup: ["deps.get", "ecto.setup"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      "ecto.seed": [
        "run priv/repo/seeds/seeds.exs",
        "run priv/subjects_repo/seeds/seeds.exs"
      ],
      itest: [
        "ecto.setup --quiet",
        "run priv/subjects_repo/seeds/seeds.exs",
        "test --only integration_test"
      ]
    ]
  end
end

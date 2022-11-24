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

defmodule FunlessWorker.MixProject do
  use Mix.Project

  def project do
    [
      app: :worker,
      version: "0.4.0",
      elixir: "~> 1.14",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      dialyzer: [
        plt_file: {:no_warn, "priv/plts/dialyzer.plt"},
        plt_add_apps: [:ex_unit, :mix]
      ],
      rustler_crates: [
        fn_wasm: [
          mode: if(Mix.env() == :dev, do: :debug, else: :release)
        ]
      ],
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger, :inets, :os_mon],
      mod: {Worker.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:rustler, "~> 0.26.0"},
      {:jason, "~> 1.3"},
      {:libcluster, "~> 3.3"},
      {:logger_file_backend, "~> 0.0.13"},
      {:telemetry, "~> 1.1.0"},
      {:telemetry_poller, "~> 1.0"},
      {:prom_ex, git: "https://github.com/akoutmos/prom_ex.git"},

      # Dev deps
      {:credo, "~> 1.6", only: [:dev, :test], runtime: false},
      {:mox, "~> 1.0", only: :test},
      {:dialyxir, "~> 1.0", only: [:dev], runtime: false}
    ]
  end

  defp elixirc_paths(:test), do: ["test/support", "lib"]
  defp elixirc_paths(_), do: ["lib"]
end

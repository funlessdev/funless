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

defmodule CoreWeb.PromEx do
  @moduledoc """
  PromEx module for CoreWeb.
  """
  use PromEx, otp_app: :core_web

  alias PromEx.Plugins

  @impl true
  def plugins do
    [
      # PromEx built in plugins
      Plugins.Application,
      Plugins.Beam,
      {Plugins.Phoenix, router: CoreWeb.Router, endpoint: CoreWeb.Endpoint}
      # Plugins.Ecto,
      # Plugins.Oban,
      # Plugins.PhoenixLiveView,
      # Plugins.Absinthe,
      # Plugins.Broadway,

      # Add your own PromEx metrics plugins
      # CoreWeb.Users.PromExPlugin
    ]
  end

  @impl true
  def dashboard_assigns do
    [
      datasource_id: " ",
      default_selected_interval: "30s"
    ]
  end

  @impl true
  def dashboards do
    [
      # PromEx built in Grafana dashboards
      {:prom_ex, "application.json"},
      {:prom_ex, "beam.json"},
      {:prom_ex, "phoenix.json"}
      # {:prom_ex, "ecto.json"},
      # {:prom_ex, "oban.json"},
      # {:prom_ex, "phoenix_live_view.json"},
      # {:prom_ex, "absinthe.json"},
      # {:prom_ex, "broadway.json"},

      # Add your dashboard definitions here with the format: {:otp_app, "path_in_priv"}
      # {:core_web, "/grafana_dashboards/user_metrics.json"}
    ]
  end
end

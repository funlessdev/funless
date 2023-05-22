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

defmodule Worker.PromEx.Plugins.NodeInfo do
  @moduledoc """
  This plugin exposes the node's user-defined long_name and tag as PromEx metrics.
  """
  use PromEx.Plugin

  @node_info_event [:prom_ex, :plugin, :node_info, :labels]

  @impl true
  def event_metrics(opts) do
    otp_app = Keyword.fetch!(opts, :otp_app)
    metric_prefix = Keyword.get(opts, :info_prefix, PromEx.metric_prefix(otp_app, :node_info))

    [
      node_info_metrics(metric_prefix)
    ]
  end

  defp node_info_metrics(metric_prefix) do
    Event.build(
      :node_info_event_metrics,
      [
        last_value(
          metric_prefix ++ [:labels, :long_name],
          event_name: @node_info_event,
          description: "The user-defined name for this node.",
          measurement: :long_name
        ),
        last_value(
          metric_prefix ++ [:labels, :tag],
          event_name: @node_info_event,
          description: "The user-defined tag for this node.",
          measurement: :tag
        )
      ]
    )
  end
end

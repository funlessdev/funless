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

defmodule Worker.PromEx.Plugins.ServicesMon do
  @moduledoc """
  This plugin exposes metrics from the external service cache.
  """
  use PromEx.Plugin

  require Logger

  alias Worker.Domain.Ports.ExternalServiceStorage

  @latency_event [:prom_ex, :plugin, :service_mon, :latency]

  @impl true
  def polling_metrics(opts) do
    poll_rate = Keyword.get(opts, :poll_rate, 5_000)
    otp_app = Keyword.fetch!(opts, :otp_app)
    metric_prefix = Keyword.get(opts, :metric_prefix, PromEx.metric_prefix(otp_app, :service_mon))

    [
      latency_metrics(metric_prefix, poll_rate)
    ]
  end

  defp latency_metrics(metric_prefix, poll_rate) do
    Polling.build(
      :service_mon_latency_polling_events,
      poll_rate,
      {__MODULE__, :execute_latency_metrics, []},
      [
        last_value(
          metric_prefix ++ [:services, :latency],
          event_name: @latency_event,
          description: "The latency of the external services.",
          measurement: :latency,
          unit: :milliseconds,
          tags: [:node, :service]
        )
      ]
    )
  end

  @doc false
  def execute_latency_metrics() do
    {:ok, keys} = ExternalServiceStorage.keys()

    Enum.each(keys, fn svc ->
      {:ok, value} = ExternalServiceStorage.get(svc)
      :telemetry.execute(@latency_event, %{latency: value}, %{node: Node.self(), service: svc})
    end)
  end
end

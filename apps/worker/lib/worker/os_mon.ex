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

defmodule Worker.PromEx.Plugins.OsMon do
  @moduledoc """
  This plugin exposes metrics from the Erlang VM's OS monitor.
  """
  use PromEx.Plugin

  @os_mon_event [:prom_ex, :plugin, :os_mon, :resources]

  @impl true
  def polling_metrics(opts) do
    poll_rate = Keyword.get(opts, :poll_rate, 5_000)
    otp_app = Keyword.fetch!(opts, :otp_app)
    metric_prefix = Keyword.get(opts, :metric_prefix, PromEx.metric_prefix(otp_app, :os_mon))

    [
      resource_metrics(metric_prefix, poll_rate)
    ]
  end

  defp resource_metrics(metric_prefix, poll_rate) do
    Polling.build(
      :os_mon_memory_polling_events,
      poll_rate,
      {__MODULE__, :execute_os_mon_metrics, []},
      [
        # Capture the total cpu utilization of the entire node
        last_value(
          metric_prefix ++ [:resources, :cpu_utilization],
          event_name: @os_mon_event,
          description: "The total amount of cpu utilization on the node.",
          measurement: :cpu,
          unit: :native
        ),

        # Capture the total cpu utilization of the entire node
        last_value(
          metric_prefix ++ [:resources, :load_avg1],
          event_name: @os_mon_event,
          description: "The total amount of cpu utilization on the node.",
          measurement: :load_avg1,
          unit: :native
        ),

        # Capture the total cpu utilization of the entire node
        last_value(
          metric_prefix ++ [:resources, :load_avg5],
          event_name: @os_mon_event,
          description: "The total amount of cpu utilization on the node.",
          measurement: :load_avg5,
          unit: :native
        ),

        # Capture the total cpu utilization of the entire node
        last_value(
          metric_prefix ++ [:resources, :load_avg15],
          event_name: @os_mon_event,
          description: "The total amount of cpu utilization on the node.",
          measurement: :load_avg15,
          unit: :native
        ),

        # Capture the total cpu utilization of the entire node
        last_value(
          metric_prefix ++ [:resources, :free_mem],
          event_name: @os_mon_event,
          description: "The total amount of cpu utilization on the node.",
          measurement: :free_mem,
          unit: :byte
        ),

        # Capture the total cpu utilization of the entire node
        last_value(
          metric_prefix ++ [:resources, :available_mem],
          event_name: @os_mon_event,
          description: "The total amount of cpu utilization on the node.",
          measurement: :available_mem,
          unit: :byte
        ),

        # Capture the total cpu utilization of the entire node
        last_value(
          metric_prefix ++ [:resources, :total_mem],
          event_name: @os_mon_event,
          description: "The total amount of cpu utilization on the node.",
          measurement: :total_mem,
          unit: :byte
        )

        # More memory metrics here
      ]
    )
  end

  @doc false
  def execute_os_mon_metrics do
    cpu_utilization = :cpu_sup.util()

    # the load_avg value is divided by 256 to align it with data from software such as top
    # erlang docs for reference: https://www.erlang.org/doc/man/cpu_sup.html
    load_avg1 = :cpu_sup.avg1() / 256
    load_avg5 = :cpu_sup.avg5() / 256
    load_avg15 = :cpu_sup.avg15() / 256

    memory_stats = :memsup.get_system_memory_data()

    node_resources = %{
      cpu: cpu_utilization,
      load_avg1: load_avg1,
      load_avg5: load_avg5,
      load_avg15: load_avg15,
      free_mem: memory_stats[:free_memory],
      available_mem: memory_stats[:available_memory],
      total_mem: memory_stats[:system_total_memory]
    }

    :telemetry.execute(@os_mon_event, node_resources, %{})
  end
end

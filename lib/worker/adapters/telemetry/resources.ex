# Licensed to the Apache Software Foundation (ASF) under one
# or more contributor license agreements.  See the NOTICE file
# distributed with this work for additional information
# regarding copyright ownership.  The ASF licenses this file
# to you under the Apache License, Version 2.0 (the
# "License"); you may not use this file except in compliance
# with the License.  You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing,
# software distributed under the License is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
# KIND, either express or implied.  See the License for the
# specific language governing permissions and limitations
# under the License.
#

defmodule Worker.Adapters.Telemetry.Resources do
  @moduledoc """
    Contains functions used to observe system resources and emit related telemetry events.
  """
  require Logger

  @doc """
    Measures cpu utilization, load average in the last 1/5/15 minutes, and memory utilization in the system.
    Emits a [:worker, :resources] telemetry events, adding the current node as metadata.
  """
  def measure_resources do
    cpu_utilization = :cpu_sup.util()
    load_avg1 = :cpu_sup.avg1() / 256
    load_avg5 = :cpu_sup.avg5() / 256
    load_avg15 = :cpu_sup.avg15() / 256
    memory_stats = :memsup.get_system_memory_data()

    {free_memory, available_memory, total_memory} =
      {memory_stats[:free_memory], memory_stats[:available_memory],
       memory_stats[:system_total_memory]}

    resources = %{
      cpu: cpu_utilization,
      load_avg: %{
        l1: load_avg1,
        l5: load_avg5,
        l15: load_avg15
      },
      memory: %{
        free: free_memory,
        available: available_memory,
        total: total_memory
      }
    }

    :telemetry.execute([:worker, :resources], resources, %{node: node()})
  end
end

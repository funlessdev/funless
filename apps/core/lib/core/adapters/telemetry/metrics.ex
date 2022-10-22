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

defmodule Core.Adapters.Telemetry.Metrics do
  @moduledoc """
  Adapter to request telemetry data about workers.
  """
  @behaviour Core.Domain.Ports.Telemetry.Metrics

  alias Core.Adapters.Telemetry.MetricsServer

  @type metrics :: %{
          cpu: number(),
          load_avg: %{l1: number(), l5: number(), l15: number()},
          memory: %{free: number(), available: number(), total: number()}
        }

  @impl true
  @spec resources(any) :: {:ok, metrics} | {:error, :not_found}
  def resources(worker) do
    worker
    |> retrieve_metrics
    |> extract_resources
  end

  defp retrieve_metrics(worker), do: MetricsServer.get(worker)

  defp extract_resources(:not_found), do: {:error, :not_found}
  defp extract_resources(r), do: {:ok, r}
end

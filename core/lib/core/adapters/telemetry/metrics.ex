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

defmodule Core.Adapters.Telemetry.Metrics do
  @moduledoc """
  Adapter to request telemetry data about workers.
  """
  @behaviour Core.Domain.Ports.Telemetry.Metrics

  alias Core.Adapters.Telemetry.MetricsServer

  @impl true
  @spec resources(any) :: {:ok, Data.Worker.Metrics.t()} | {:error, :not_found}
  def resources(worker) do
    with {:ok, res} <-
           worker
           |> retrieve_metrics
           |> extract_resources do
      {:ok, struct(Data.Worker.Metrics, res)}
    end
  end

  @impl true
  @spec update(any, Data.Worker.t()) :: :ok | {:error, any}
  def update(worker, info) do
    MetricsServer.insert(worker, info)
  end

  defp retrieve_metrics(worker), do: MetricsServer.get(worker)

  defp extract_resources(:not_found), do: {:error, :not_found}
  defp extract_resources(r), do: {:ok, r}
end

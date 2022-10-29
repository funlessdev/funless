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

defmodule Core.Adapters.Telemetry.Collector do
  @moduledoc """
    Implements GenServer behaviour.
    A collector is spawned for each worker by the monitor and periodically pulls telemetry information from prometheus.
  """
  use GenServer, restart: :permanent
  require Logger
  alias Core.Adapters.Telemetry.MetricsServer

  def start_link(node) do
    GenServer.start_link(__MODULE__, node,
      name: {:via, Registry, {Core.Adapters.Telemetry.Registry, "telemetry_#{node}"}}
    )
  end

  @impl true
  def init(node) do
    Logger.info("Metrics Collector: started retrieving metrics of #{node}")
    send(self(), :pull)
    {:ok, node}
  end

  @impl true
  def handle_info(:pull, node) do
    retrieve(node)
    {:noreply, node}
  end

  @spec retrieve(atom()) :: reference()
  @doc """
    Pulls metrics for the given worker node every 5s.
  """
  def retrieve(worker) do
    # Get the metrics from prometheus, next project: prometheus HTTP API client library in Elixir with Tesla
    res = pull_metrics()

    case res do
      {:ok, data} ->
        metrics = parse_metrics(data)
        save_metrics(worker, metrics)

      {:error, reason} ->
        Logger.warn("Metrics Collector: error pulling metrics #{inspect(reason)}")
    end

    Process.send_after(self(), :pull, 5_000)
  end

  @spec save_metrics(atom(), map()) :: :ok
  defp save_metrics(worker, metrics) do
    if Map.has_key?(metrics, "worker_prom_ex_beam_memory_allocated_bytes") do
      mem = metrics["worker_prom_ex_beam_memory_allocated_bytes"]
      MetricsServer.insert(worker, %{memory: mem})
    end

    :ok
  end

  @spec parse_metrics(map()) :: map()
  defp parse_metrics(%{"data" => %{"result" => result_list}, "status" => "success"}) do
    Enum.reduce(result_list, %{}, fn result, acc ->
      case result do
        %{"metric" => %{"__name__" => name}, "value" => [_, value]} ->
          Map.put(acc, name, value)

        _ ->
          acc
      end
    end)
  end

  defp parse_metrics(_), do: %{}

  @spec pull_metrics() :: {:ok, map()} | {:error, any()}
  defp pull_metrics do
    prom_url =
      "http://prometheus:9090/api/v1/query?query=worker_prom_ex_beam_memory_allocated_bytes"

    response = :httpc.request(:get, {prom_url, []}, [], [])

    case response do
      {:ok, {_response_status, _headers, json_body}} ->
        metrics = Jason.decode!(json_body)
        {:ok, metrics}

      {:error, reason} ->
        {:error, reason}
    end
  end
end

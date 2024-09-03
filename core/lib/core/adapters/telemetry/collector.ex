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

defmodule Core.Adapters.Telemetry.Collector do
  @moduledoc """
    Implements GenServer behaviour.
    A collector is spawned for each worker by the monitor and periodically pulls telemetry information from prometheus.
  """
  use GenServer, restart: :permanent
  require Logger
  alias Core.Adapters.Telemetry.MetricsServer

  @prom_url_query "/api/v1/query?"
  # @beam_memory_allocated "worker_prom_ex_beam_memory_allocated_bytes"
  @os_mon_prefix "worker_prom_ex_os_mon_resources_"
  @available_mem "available_mem"
  @free_mem "free_mem"
  @total_mem "total_mem"
  @load_avg "load_avg"
  @cpu_util "cpu_utilization"

  def start_link(node) do
    GenServer.start_link(__MODULE__, node,
      name: {:via, Registry, {Core.Adapters.Telemetry.Registry, "telemetry_#{node}"}}
    )
  end

  @impl true
  def init(node) do
    Logger.info("Metrics Collector: started retrieving metrics of #{node}")

    {long_name, tag} =
      case GenServer.call({:worker, node}, :get_info) do
        {:ok, n, t} -> {n, t}
        _ -> {node, node}
      end

    MetricsServer.insert(
      node,
      struct(Data.Worker, %{
        name: node,
        long_name: long_name,
        tag: tag,
        resources: %Data.Worker.Metrics{},
        concurrent_functions: 0
      })
    )

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
    res = pull_metrics(worker)

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
    {current_info, current_metrics} =
      case MetricsServer.get(worker) do
        :not_found -> {struct(Data.Worker, %{name: worker}), %{}}
        %Data.Worker{resources: %Data.Worker.Metrics{} = m} = w -> {w, Map.from_struct(m)}
      end

    Logger.info("Received metrics for #{worker}: #{inspect(metrics)}")

    scraped_metrics =
      %{
        cpu: metrics |> Map.get(@os_mon_prefix <> @cpu_util),
        memory:
          %{
            free: metrics |> Map.get(@os_mon_prefix <> @free_mem),
            total: metrics |> Map.get(@os_mon_prefix <> @total_mem),
            available: metrics |> Map.get(@os_mon_prefix <> @available_mem)
          }
          |> Map.filter(fn {_, v} -> v != nil end),
        load_avg:
          %{
            l1: metrics |> Map.get(@os_mon_prefix <> @load_avg <> "1"),
            l5: metrics |> Map.get(@os_mon_prefix <> @load_avg <> "5"),
            l15: metrics |> Map.get(@os_mon_prefix <> @load_avg <> "15")
          }
          |> Map.filter(fn {_, v} -> v != nil end),
        latencies: metrics |> Map.get("latencies")
      }
      |> Map.filter(fn {_, v} -> v != nil end)

    new_metrics = struct(Data.Worker.Metrics, Map.merge(current_metrics, scraped_metrics))

    new_info = current_info |> Map.put(:resources, new_metrics)

    MetricsServer.insert(worker, new_info)

    Logger.info("Metrics Collector: saved metrics for #{worker}, #{inspect(new_metrics)}")
    :ok
  end

  @spec parse_metrics(map()) :: map()
  defp parse_metrics(%{"data" => %{"result" => result_list}, "status" => "success"}) do
    parsed_res = %{"latencies" => %{}}

    Enum.reduce(result_list, parsed_res, fn result, acc ->
      case result do
        %{"metric" => %{"service" => svc}, "value" => [_, value]} ->
          {float_val, _} = Float.parse(value)
          put_in(acc, ["latencies", svc], float_val)

        %{"metric" => %{"__name__" => name}, "value" => [_, value]} ->
          {float_val, _} = Float.parse(value)
          Map.put(acc, name, float_val)

        _ ->
          acc
      end
    end)
  end

  defp parse_metrics(_), do: %{}

  @spec pull_metrics(atom()) :: {:ok, map()} | {:error, any()}
  defp pull_metrics(worker) do
    prom_host = Application.fetch_env!(:core, :prometheus_host)
    prom_query = :uri_string.compose_query([{"query", "{node=\"#{Atom.to_string(worker)}\"}"}])
    prom_uri = "http://#{prom_host}:9090#{@prom_url_query}#{prom_query}"

    response = :httpc.request(:get, {prom_uri, []}, [], [])

    case response do
      {:ok, {_response_status, _headers, json_body}} ->
        metrics = Jason.decode!(json_body)
        {:ok, metrics}

      {:error, reason} ->
        {:error, reason}
    end
  end
end

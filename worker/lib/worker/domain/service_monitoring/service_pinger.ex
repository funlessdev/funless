defmodule Worker.Domain.ServiceMonitoring.ServicePinger do
  use GenServer

  require Logger

  alias Worker.Domain.Ports.ExternalServiceStorage

  # Public API

  def start_link({url, interval_ms}) do
    Logger.info("Pinger for: '#{url}' with interval: #{interval_ms} ms started")

    GenServer.start_link(__MODULE__, {url, interval_ms}, name: String.to_atom(url))
  end

  def get_latency(url) do
    GenServer.call(String.to_atom(url), :get_latency)
  end

  # GenServer Callbacks

  @impl true
  def init({url, interval_ms}) do
    schedule_ping(interval_ms)
    {:ok, %{url: url, interval_ms: interval_ms, last_latency: nil}}
  end

  @impl true
  def handle_info(:ping, state) do
    latency = ping_service(state.url)
    ExternalServiceStorage.upsert(state.url, latency)
    schedule_ping(state.interval_ms)

    {:noreply, %{state | last_latency: latency}}
  end

  @impl true
  def handle_call(:get_latency, _from, state) do
    {:reply, state.last_latency, state}
  end

  # Helper functions

  defp schedule_ping(interval_ms) do
    Process.send_after(self(), :ping, interval_ms)
  end

  defp ping_service(url) do
    Logger.info("Pinging #{url}...")
    start_time = :os.system_time(:millisecond)

    case HTTPoison.get(url) do
      {:ok, %HTTPoison.Response{status_code: 200}} ->
        end_time = :os.system_time(:millisecond)
        latency = end_time - start_time
        Logger.info("#{url} is up. Latency: #{latency} ms")
        latency

      {:ok, %HTTPoison.Response{status_code: code}} ->
        end_time = :os.system_time(:millisecond)
        latency = end_time - start_time
        Logger.warning("#{url} responded with status code #{code}. Latency: #{latency} ms")
        latency

      {:error, %HTTPoison.Error{reason: reason}} ->
        end_time = :os.system_time(:millisecond)
        latency = end_time - start_time
        Logger.error("#{url} is down: #{reason}. Latency: #{latency} ms")
        latency
    end
  end
end

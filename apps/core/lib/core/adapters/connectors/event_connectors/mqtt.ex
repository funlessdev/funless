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

defmodule Core.Adapters.Connectors.EventConnectors.Mqtt do
  @moduledoc """
  Event Connector for MQTT messages.
  """
  use GenServer
  require Logger
  alias Core.Domain.Invoker
  alias Data.InvokeParams

  def start_link(params) do
    GenServer.start_link(__MODULE__, params)
  end

  def init(%{
        function: function,
        module: module,
        params: %{"host" => host, "port" => port, "topic" => topic}
      }) do
    Process.flag(:trap_exit, true)

    # params come from json, but emqtt only accepts atoms as host and integers as port
    case host |> String.to_charlist() |> :inet.getaddr(:inet) do
      {:ok, address} ->
        params = %{host: address, port: String.to_integer(port), topic: topic}

        case connect_to_broker(params) do
          {:ok, pid} ->
            Logger.info("MQTT Event Connector: started with params #{inspect(params)}")

            {:ok,
             params
             |> Map.put(:pid, pid)
             |> Map.put(:function, function)
             |> Map.put(:module, module)}

          {:error, err} ->
            Logger.warn("MQTT Event Connector failed to start with error: #{inspect(err)}")
            {:stop, :normal}

          other ->
            Logger.warn("MQTT Event Connector failed to start with reason: #{inspect(other)}")
            {:stop, :normal}
        end

      _ ->
        {:stop, :normal}
    end
  end

  def handle_info(
        {:publish, _msg = %{payload: payload}},
        %{function: function, module: module} = params
      ) do
    with {:ok, json_payload} <- Jason.decode(payload),
         ivk <- %InvokeParams{
           function: function,
           module: module,
           args: json_payload
         },
         {:ok, res} <- Invoker.invoke(ivk) do
      Logger.info("MQTT Event Connector: #{module}/#{function} invoked with res #{inspect(res)}")
    else
      {:error, err} ->
        Logger.warn(
          "MQTT Event Connector: invocation of #{module}/#{function} failed with error #{inspect(err)}"
        )

      other ->
        Logger.warn(
          "MQTT Event Connector: invocation of #{module}/#{function} failed with cause #{inspect(other)}"
        )
    end

    {:noreply, params}
  end

  def handle_info({:disconnect, _reason, _props}, params) do
    Logger.warn(
      "MQTT Event Connector (host #{params.host}, port #{params.port}, topic #{params.topic}): disconnected from broker"
    )

    case connect_to_broker(params) do
      {:ok, pid} ->
        Logger.info("MQTT Event Connector: reconnected")
        {:noreply, params |> Map.put(:pid, pid)}

      _ ->
        Logger.warn("MQTT Event Connector: reconnect failed, killing Connector")
        {:stop, :normal, params}
    end
  end

  def handle_info({:EXIT, pid, reason}, %{pid: pid} = params) do
    Logger.warn(
      "MQTT Event Connector (host #{params.host}, port #{params.port}, topic #{params.topic}): emqtt process died with reason #{inspect(reason)}"
    )

    case connect_to_broker(params) do
      {:ok, pid} ->
        Logger.info("MQTT Event Connector: emqtt process restarted")
        {:noreply, params |> Map.put(:pid, pid)}

      _ ->
        Logger.warn("MQTT Event Connector: emqtt process restart failed, killing Connector")
        {:stop, :normal, params}
    end
  end

  # exit messages from other processes are handled normally, shutting the GenServer down gracefully with terminate()
  def handle_info({:EXIT, _pid, reason}, params) do
    {:stop, reason, params}
  end

  def terminate(_reason, %{pid: pid, topic: topic} = _params) do
    if Process.alive?(pid) do
      :emqtt.unsubscribe(pid, %{}, topic)
      :emqtt.disconnect(pid)

      # `disconnect` actually sends a `stop_and_reply` message to the gen_statem, so calling stop as well is redundant
      # :emqtt.stop(pid)
    end
  end

  defp connect_to_broker(%{host: host, port: port, topic: topic} = _params) do
    with {:ok, pid} <- :emqtt.start_link([{:host, host}, {:port, port}]),
         {:ok, _props} <- :emqtt.connect(pid),
         {:ok, _props, _reasons} <- :emqtt.subscribe(pid, %{}, [{topic, []}]) do
      {:ok, pid}
    end
  end
end

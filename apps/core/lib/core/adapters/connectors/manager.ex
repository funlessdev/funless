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

defmodule Core.Adapters.Connectors.Manager do
  @moduledoc """
  Adapter to handle Event Connector processes and associate functions to events.
  """
  @main_supervisor Core.Adapters.Connectors.DynamicSupervisor
  @registry Core.Adapters.Connectors.Registry

  @behaviour Core.Domain.Ports.Connectors.Manager
  alias Core.Adapters.Connectors.EventConnectors
  alias Core.Domain.Ports.Connectors.Manager
  alias Data.ConnectedEvent

  require Logger

  @impl true
  def connect(%{name: function, module: module}, %ConnectedEvent{
        type: event_type,
        params: params
      }) do
    # calling which_connector from the port instead of the current file, to allow mocking
    with {:ok, connector} <- Manager.which_connector(event_type) do
      Logger.debug(
        "ConnectorManager: connecting #{event_type} to #{module}/#{function} with #{inspect(params)}"
      )

      # dedicated DynamicSupervisor name for this function's Event Connectors
      name = "#{Atom.to_string(@main_supervisor)}.#{module}/#{function}"
      supervisor = {:via, Registry, {@registry, name}}

      @registry
      |> Registry.lookup(supervisor)
      |> start_connector_process(supervisor, connector, %{
        function: function,
        module: module,
        params: params
      })
    end
  end

  # if the supervisor does not exist start it and add the child
  defp start_connector_process([], supervisor, connector, args) do
    DynamicSupervisor.start_child(
      @main_supervisor,
      {DynamicSupervisor,
       strategy: :one_for_one, max_restarts: 5, max_seconds: 5, name: supervisor}
    )

    start_connector(supervisor, connector, args)
  end

  # if the supervisor already exists add the new process to it
  defp start_connector_process([{pid, _}], supervisor, connector, args) do
    if Process.alive?(pid) do
      start_connector(supervisor, connector, args)
    else
      {:error, :supervisor_stopping}
    end
  end

  defp start_connector(supervisor, connector, args) do
    result =
      DynamicSupervisor.start_child(
        supervisor,
        {connector, args}
      )

    case result do
      {:ok, _pid} -> :ok
      {:ok, _pid, _info} -> :ok
      :ignore -> {:error, :ignore}
      {:error, err} -> {:error, err}
    end
  end

  @impl true
  def which_connector(event_type) do
    case event_type do
      "mqtt" -> {:ok, EventConnectors.Mqtt}
      _ -> {:error, :not_implemented}
    end
  end

  @impl true
  def disconnect(%{name: function, module: module}) do
    supervisor = "#{Atom.to_string(@main_supervisor)}.#{module}/#{function}"

    Registry.lookup(@registry, supervisor)
    |> Enum.each(fn {pid, _} -> DynamicSupervisor.terminate_child(@main_supervisor, pid) end)
  end
end

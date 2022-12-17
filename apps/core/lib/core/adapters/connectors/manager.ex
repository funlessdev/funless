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

  @impl true
  def connect(%{name: function, module: module}, %ConnectedEvent{
        type: event_type,
        params: params
      }) do
    # calling which_connector from the port instead of the current file, to allow mocking
    with {:ok, connector} <- Manager.which_connector(event_type) do
      # dedicated DynamicSupervisor name for this function's Event Connectors
      name = "#{Atom.to_string(@main_supervisor)}.#{module}/#{function}"
      supervisor = {:via, Registry, {@registry, name}}

      # if the supervisor already exists, add the new process to it; otherwise start the supervisor, and add the child
      if Registry.lookup(@registry, supervisor) == [] do
        DynamicSupervisor.start_child(
          @main_supervisor,
          {DynamicSupervisor,
           strategy: :one_for_one, max_restarts: 5, max_seconds: 5, name: supervisor}
        )
      end

      result =
        DynamicSupervisor.start_child(
          supervisor,
          {connector,
           %{
             function: function,
             module: module,
             params: params
           }}
        )

      case result do
        {:ok, _pid} ->
          :ok

        {:ok, _pid, _info} ->
          :ok

        :ignore ->
          {:error, :ignore}

        {:error, err} ->
          {:error, err}
      end
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

    case Registry.lookup(@registry, supervisor) do
      [] ->
        {:error, :not_found}

      [{pid, _}] ->
        DynamicSupervisor.terminate_child(@main_supervisor, pid)
        :ok
    end
  end
end

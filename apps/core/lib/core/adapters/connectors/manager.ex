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
  @behaviour Core.Domain.Ports.Connectors.Manager
  alias Core.Adapters.Connectors.EventConnectors
  alias Core.Adapters.Connectors.ManagerStore
  alias Data.ConnectedEvent

  @impl true
  def connect(%{name: function, module: module}, %ConnectedEvent{
        type: event_type,
        params: params
      }) do
    result =
      case event_type do
        "mqtt" ->
          DynamicSupervisor.start_child(
            Core.Adapters.Connectors.DynamicSupervisor,
            {EventConnectors.Mqtt, %{function: function, module: module, params: params}}
          )
      end

    case result do
      {:ok, pid} ->
        ManagerStore.insert(function, module, pid)
        :ok

      {:ok, pid, _info} ->
        ManagerStore.insert(function, module, pid)
        :ok

      :ignore ->
        {:error, :ignore}

      {:error, err} ->
        {:error, err}
    end
  end

  @impl true
  def disconnect(%{name: function, module: module}) do
    case ManagerStore.get(function, module) do
      :not_found ->
        {:error, :not_found}

      pids ->
        Enum.each(pids, fn pid ->
          DynamicSupervisor.terminate_child(Core.Adapters.Connectors.DynamicSupervisor, pid)
        end)

        ManagerStore.delete(function, module)
        :ok
    end
  end
end

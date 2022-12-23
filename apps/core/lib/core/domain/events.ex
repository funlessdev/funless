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

defmodule Core.Domain.Events do
  @moduledoc """

  """
  alias Core.Domain.Ports.Connectors.Manager

  @spec connect_events(String.t(), String.t(), [map()] | nil) :: [:ok | {:error, any}]
  def connect_events(_, _, nil) do
    []
  end

  def connect_events(function, module, [_] = events) do
    Enum.map(events, fn e -> connect_single_event(function, module, e) end)
  end

  @spec connect_single_event(String.t(), String.t(), map) :: :ok | {:error, any}
  def connect_single_event(function, module, %{"type" => type, "params" => params}) do
    connected_event = %Data.ConnectedEvent{type: type, params: params}
    Manager.connect(%{name: function, module: module}, connected_event)
  end

  def connect_single_event(_, _, _) do
    {:error, :bad_event_format}
  end

  @spec update_events(String.t(), String.t(), [map()] | nil) :: [:ok | {:error, any}]
  def update_events(_, _, nil) do
    []
  end

  def update_events(function, module, [_] = events) do
    Manager.disconnect(%{name: function, module: module})
    connect_events(function, module, events)
  end

  @spec disconnect_events(String.t(), String.t()) :: :ok | {:error, any}
  def disconnect_events(function, module) do
    Manager.disconnect(%{name: function, module: module})
  end
end

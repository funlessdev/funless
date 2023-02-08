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

defmodule Core.Domain.Events do
  @moduledoc """
    Wrapper for Core.Domain.Ports.Connectors.Manager; allows for easier interaction and interrogation
    from driver adapters and other apps (e.g. core_web).
  """
  alias Core.Domain.Ports.Connectors.Manager

  @spec connect_events(String.t(), String.t(), [map()] | nil) :: [:ok | {:error, any}]
  @doc """
    Connects multiple events to a function.

    ## Parameters
    - function: the name of the function
    - module: the module containing the function
    - events: a list of maps containing event properties

    ## Returns
    A list of multiple results, each with value:
    - :ok if the event was connected successfully
    - {:error, err} if the event failed to connect for some reason
  """
  def connect_events(_, _, ev) when is_nil(ev) or ev == [], do: []

  def connect_events(function, module, [_ | _] = events) do
    Enum.map(events, fn e -> connect_single_event(function, module, e) end)
  end

  @doc """
    Connects a single event to a function, building the event from a generic map.

    ## Parameters
    - function: the name of the function
    - module: the module containing the function
    - _event: a map containig the "type" and "params" keys

    ## Returns
    - :ok if the event was connected successfully
    - {:error, :bad_event_format} if the event map did not contain the necessary keys
    - {:error, err} if an error occurred during connection
  """
  @spec connect_single_event(String.t(), String.t(), map) :: :ok | {:error, any}
  def connect_single_event(function, module, %{"type" => type, "params" => params} = _event) do
    connected_event = %Data.ConnectedEvent{type: type, params: params}
    Manager.connect(%{name: function, module: module}, connected_event)
  end

  def connect_single_event(_, _, _), do: {:error, :bad_event_format}

  @doc """
    Update the events a function is connected to; disconnects the function from all previous events
    and connects it to the new ones.

    ## Parameters
    - function: the name of the function
    - module: the module containing the function
    - events: a list of maps containing event properties

    ## Returns
    A list of multiple results, each with value:
    - :ok if the event was connected successfully
    - {:error, err} if the event failed to connect for some reason
  """
  @spec update_events(String.t(), String.t(), [map()] | nil) :: [:ok | {:error, any}]
  def update_events(_, _, ev) when is_nil(ev) or ev == [], do: []

  def update_events(function, module, [_ | _] = events) do
    Manager.disconnect(%{name: function, module: module})
    connect_events(function, module, events)
  end

  @doc """
    Disconnects all events from a function.

    ## Parameters
    - function: the name of the function
    - module: the module containing the function

    ## Returns
    - :ok if the disconnection was successful
    - {:error, err} if the disconnection failed
  """
  @spec disconnect_events(String.t(), String.t()) :: :ok | {:error, any}
  def disconnect_events(function, module) do
    Manager.disconnect(%{name: function, module: module})
  end
end

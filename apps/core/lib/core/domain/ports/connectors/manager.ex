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

defmodule Core.Domain.Ports.Connectors.Manager do
  @moduledoc """
  Port for managing Event Connectors.
  """
  alias Data.ConnectedEvent

  @type function_signature :: %{
          name: String.t(),
          module: String.t()
        }

  @adapter :core |> Application.compile_env!(__MODULE__) |> Keyword.fetch!(:adapter)

  @callback connect(function_signature, ConnectedEvent.t()) :: :ok | {:error, any}
  @callback disconnect(function_signature) :: :ok | {:error, any}

  @doc """
  Connects a function to a specific event. Should spawn a connector process.
  """
  @spec connect(function_signature, ConnectedEvent.t()) :: :ok | {:error, any}
  defdelegate connect(function, event), to: @adapter

  @doc """
  Disconnects a function from all events. Should kill all related connector processes.
  """
  @spec disconnect(function_signature) :: :ok | {:error, any}
  defdelegate disconnect(function), to: @adapter
end

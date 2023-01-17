# Copyright 2022 Giuseppe De Palma, Matteo Trentin
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

defmodule Core.Domain.Ports.DataSinks.Manager do
  @moduledoc """
  Port for managing Event Connectors.
  """
  alias Data.DataSink

  @type function_signature :: %{
          name: String.t(),
          module: String.t()
        }

  @type event_type :: String.t()

  @adapter :core |> Application.compile_env!(__MODULE__) |> Keyword.fetch!(:adapter)

  @callback plug(function_signature, DataSink.t()) :: :ok | {:error, any}
  @callback which_data_sink(event_type) :: {:ok, module()} | {:error, :not_implemented}
  @callback unplug(function_signature) :: :ok | {:error, any}
  @callback get_all(String.t(), String.t()) :: {:ok, [pid()]} | {:error, :not_found}

  @doc """
  Connects a function to a specific event. Should spawn a connector process.
  """
  @spec plug(function_signature, DataSink.t()) :: :ok | {:error, any}
  defdelegate plug(function, event), to: @adapter

  @doc """
  Specifies which connector should be called for a certain event type.
  """
  @spec which_data_sink(event_type) :: {:ok, module()} | {:error, any}
  defdelegate which_data_sink(event_type), to: @adapter

  @doc """
  Disconnects a function from all events. Should kill all related connector processes.
  """
  @spec unplug(function_signature) :: :ok | {:error, any}
  defdelegate unplug(function), to: @adapter

  @doc """
  Returns all the data sinks for a given function.
  """
  @spec get_all(String.t(), String.t()) :: {:ok, [pid()]} | {:error, :not_found}
  defdelegate get_all(module, function), to: @adapter
end

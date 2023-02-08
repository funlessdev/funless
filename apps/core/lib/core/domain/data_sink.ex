# Copyright 2023 Giuseppe De Palma, Matteo Trentin
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

defmodule Core.Domain.DataSink do
  @moduledoc """
    DataSink is a domain module that provides functions to connect functions to data sinks.
    Data sinks allow function outputs to be sent to external systems (e.g. databases, storage, etc).
  """
  alias Core.Domain.Ports.DataSinks.Manager

  @spec plug_data_sinks(String.t(), String.t(), [map()] | nil) :: [:ok | {:error, any}]
  def plug_data_sinks(_, _, ds) when is_nil(ds) or ds == [], do: []

  def plug_data_sinks(function, module, [_ | _] = ds) do
    Enum.map(ds, &plug_single_data_sink(function, module, &1))
  end

  @spec plug_single_data_sink(String.t(), String.t(), map) :: :ok | {:error, any}
  def plug_single_data_sink(function, module, %{"type" => type, "params" => params} = _sink) do
    plugged_ds = %Data.DataSink{type: type, params: params}
    Manager.plug(%{name: function, module: module}, plugged_ds)
  end

  def plug_single_data_sink(_, _, _), do: {:error, :bad_sink_format}

  @spec update_data_sinks(String.t(), String.t(), [map()] | nil) :: [:ok | {:error, any}]
  def update_data_sinks(_, _, ds) when is_nil(ds) or ds == [], do: []

  def update_data_sinks(function, module, [_ | _] = ds) do
    Manager.unplug(%{name: function, module: module})
    plug_data_sinks(function, module, ds)
  end

  @spec unplug_data_sink(String.t(), String.t()) :: :ok | {:error, any}
  def unplug_data_sink(function, module) do
    Manager.unplug(%{name: function, module: module})
  end
end

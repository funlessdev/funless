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

defmodule Core.Domain.Ports.Telemetry.Metrics do
  @moduledoc """
  Port for requesting telemetry information about workers.
  """

  @type worker :: atom()
  @adapter :core |> Application.compile_env!(__MODULE__) |> Keyword.fetch!(:adapter)

  @callback resources(worker) :: {:ok, Data.Worker.Metrics.t()} | {:error, :not_found}
  @callback update(worker, Data.Worker.t()) :: :ok | {:error, any}

  @doc """
  Function to obtain resource information on a specific worker.
  """
  @spec resources(worker) :: {:ok, Data.Worker.Metrics.t()} | {:error, :not_found}
  defdelegate resources(worker), to: @adapter

  @doc """
  Function to update the information about a specific worker.
  """
  @spec update(worker, Data.Worker.t()) :: :ok | {:error, any}
  defdelegate update(worker, metrics), to: @adapter
end

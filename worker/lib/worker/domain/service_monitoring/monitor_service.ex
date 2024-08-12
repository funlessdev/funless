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
defmodule Worker.Domain.ServiceMonitoring.MonitorService do
  @moduledoc """
  Contains functions regarding the update/insertion of node information.
  """
  require Logger

  alias Worker.Domain.Ports.ExternalServiceStorage
  alias Worker.Domain.ServiceMonitoring.ServicePingerSupervisor
  alias Worker.Domain.ServiceMonitoring.ServicePinger

  alias Data.ServiceMetadataStruct

  @interval 10000

  @spec add_service(nil | Data.ServiceMetadataStruct.t()) ::
          {:error, term() | :no_service} | :ok
  def add_service(%ServiceMetadataStruct{} = s) do
    Logger.info("Starting service pinger for #{s.name}")

    DynamicSupervisor.start_child(
      ServicePingerSupervisor,
      {ServicePinger, {s.name, s.endpoint, @interval}}
    )
    |> case do
      {:ok, _pid} -> :ok
      {:error, err} -> {:error, err}
    end
  end

  def add_service(nil) do
    {:error, :no_service}
  end

  def get_service_latency(name) do
    with {:ok, ep} <- ExternalServiceStorage.get(name) do
      {:ok, ep}
    end
  end
end

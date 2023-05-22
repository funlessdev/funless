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
defmodule Worker.Domain.NodeInfo do
  @moduledoc """
  Contains functions regarding the update/insertion of node information.
  """
  alias Worker.Domain.Ports.NodeInfoStorage

  @node_info_event [:prom_ex, :plugin, :node_info, :labels]

  def update_node_info(name, nil) do
    with {:ok, tag} <- NodeInfoStorage.get("tag"),
         :ok <- NodeInfoStorage.update("long_name", name) do
      :telemetry.execute(@node_info_event, %{long_name: name, tag: tag})
    end
  end

  def update_node_info(nil, tag) do
    with {:ok, name} <- NodeInfoStorage.get("long_name"),
         :ok <- NodeInfoStorage.update("tag", tag) do
      :telemetry.execute(@node_info_event, %{long_name: name, tag: tag})
    end
  end

  def update_node_info(name, tag) do
    with :ok <- NodeInfoStorage.update("long_name", name),
         :ok <- NodeInfoStorage.update("tag", tag) do
      :telemetry.execute(@node_info_event, %{long_name: name, tag: tag})
    end
  end
end

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

defmodule Core.Domain.Ports.Cluster do
  @moduledoc """
  Port for retrieving data about the deployed funless platform.
  """

  @adapter :core |> Application.compile_env!(__MODULE__) |> Keyword.fetch!(:adapter)

  @callback all_nodes() :: list(atom())

  @doc """
  Function to obtain a list with all active nodes in the cluster,
  which can be processed to retrieve all worker nodes.
  """
  @spec all_nodes :: list(atom())
  defdelegate all_nodes, to: @adapter
end

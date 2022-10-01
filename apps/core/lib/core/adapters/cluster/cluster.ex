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

defmodule Core.Adapters.Cluster do
  @moduledoc """
  Adapter to retrieve data from the cluster funless is deployed on.
  """
  @behaviour Core.Domain.Ports.Cluster

  @impl true
  @spec all_nodes :: [atom]
  def all_nodes, do: Node.list()
end

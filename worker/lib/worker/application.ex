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

defmodule Worker.Application do
  @moduledoc false
  alias Worker.Adapters

  use Application

  @impl true
  def start(_type, _args) do
    topologies = Application.fetch_env!(:worker, :topologies)

    children = [
      {Cachex, name: :node_info_cache},
      Worker.PromEx,
      {Cluster.Supervisor, [topologies, [name: Worker.ClusterSupervisor]]},
      {Adapters.Requests.Cluster.Server, []},
      {Worker.Domain.Ports.Runtime.Supervisor, []}
    ]

    Supervisor.start_link(children, strategy: :rest_for_one)
  end
end

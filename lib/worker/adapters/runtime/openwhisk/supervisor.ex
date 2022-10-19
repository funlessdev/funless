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

defmodule Worker.Adapters.Runtime.OpenWhisk.Supervisor do
  @moduledoc """
  Supervisor for the openwhisk runtime. It implements the behaviour of Ports.Runtime.Supervisor to define the children to supervise.
  """
  @behaviour Worker.Domain.Ports.Runtime.Supervisor

  @impl true
  def children do
    [
      {Worker.Adapters.ResourceCache, []}
    ]
  end
end

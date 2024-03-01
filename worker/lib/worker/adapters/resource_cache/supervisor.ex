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

defmodule Worker.Adapters.ResourceCache.Supervisor do
  @moduledoc """
  Supervisor for the Cachex ResourceCache.
  It implements the behaviour of Ports.ResourceCache.Supervisor to define the children to supervise.
  Starts Cachex.
  """
  @behaviour Worker.Domain.Ports.ResourceCache.Supervisor
  @cache :resource_cache

  @impl true
  def children do
    [
      {Cachex, name: @cache}
    ]
  end
end

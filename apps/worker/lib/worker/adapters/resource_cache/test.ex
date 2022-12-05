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

defmodule Worker.Adapters.ResourceCache.Test do
  @moduledoc false
  @behaviour Worker.Domain.Ports.ResourceCache
  alias Worker.Domain.ExecutionResource

  @impl true
  def get(_function_name, _module) do
    %ExecutionResource{resource: "runtime"}
  end

  @impl true
  def insert(_name, _ns, _runtime) do
    :ok
  end

  @impl true
  def delete(_name, _ns) do
    :ok
  end
end

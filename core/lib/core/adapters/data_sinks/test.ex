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

defmodule Core.Adapters.DataSinks.Test do
  @moduledoc false

  @behaviour Core.Domain.Ports.DataSinks.Manager

  @impl true
  def get_all(_module, _function) do
    {:ok, []}
  end

  @impl true
  def plug(_function_signature, _event) do
    :ok
  end

  @impl true
  def which_data_sink(_) do
    {:ok, Core.Adapters.Connectors.EventConnectors.Test}
  end

  @impl true
  def unplug(_function_signature) do
    :ok
  end
end

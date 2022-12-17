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

defmodule Core.Adapters.Connectors.Test do
  @moduledoc false

  @behaviour Core.Domain.Ports.Connectors.Manager

  @impl true
  def connect(_function_signature, _event) do
    :ok
  end

  @impl true
  def which_connector(_) do
    {:ok, Core.Adapters.Connectors.EventConnectors.Test}
  end

  @impl true
  def disconnect(_function_signature) do
    :ok
  end
end

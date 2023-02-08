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

defmodule Core.Adapters.Telemetry.Test do
  @moduledoc false
  @behaviour Core.Domain.Ports.Telemetry.Metrics

  @impl true
  def resources(_worker) do
    {:ok,
     %{
       cpu: 1,
       load_avg: %{l1: 1, l5: 5, l15: 15},
       memory: %{free: 20, available: 10, total: 50}
     }}
  end
end

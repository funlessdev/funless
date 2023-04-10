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

defmodule Data.Worker.Metrics do
  @type t :: %__MODULE__{
          cpu: number(),
          load_avg: %{l1: number(), l5: number(), l15: number()},
          memory: %{free: number(), available: number(), total: number()}
        }
  defstruct [:cpu, :load_avg, :memory]
end

defmodule Data.Worker do
  @type t :: %__MODULE__{
          name: atom(),
          resources: Data.Worker.Metrics,
          tag: String.t()
        }
  @enforce_keys [:name]
  defstruct [:name, :resources, :tag]
end

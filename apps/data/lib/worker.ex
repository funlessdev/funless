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

defmodule Data.Worker do
  @moduledoc """
  Struct describing a Worker node.

  ## Fields
    - name: name of BEAM instance hosting the Worker
    - long_name: string representing a symbolic name for the worker; can be unrelated to the :name attribute
    - resources: metrics collected about the Worker
    - tag: tag of the Worker, used to group it with similar ones
    - concurrent_functions: number of functions currently running on the Worker
  """
  @type t :: %__MODULE__{
          name: atom(),
          long_name: String.t(),
          resources: Data.Worker.Metrics.t(),
          tag: String.t(),
          concurrent_functions: integer()
        }
  @enforce_keys [:name]
  defstruct [:name, :long_name, :resources, :tag, :concurrent_functions]
end

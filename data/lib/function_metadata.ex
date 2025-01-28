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

defmodule Data.FunctionMetadata do
  @moduledoc """
  A struct that represents the metadata associated with a function.

  ## Fields
    - tag: a string containing the function's tag. Can be anything, generally used with custom scheduling policies or metrics.
    - capacity: the amount of memory this function requires to be allocated on a worker
  """
  @type t :: %__MODULE__{
          tag: String.t(),
          capacity: integer()
        }
  defstruct tag: "", capacity: -1
end

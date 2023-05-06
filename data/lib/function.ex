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

defmodule Data.FunctionStruct do
  @moduledoc """
    Function struct that represents a function in the platform. It has
    the suffix `Struct` to avoid name collision with the `Function` module.

    ## Fields
      - name: function name
      - module: function module
      - code: function code binary
      - metadata: additional information about the function
  """
  @type t :: %__MODULE__{
          module: String.t(),
          name: String.t(),
          code: binary(),
          metadata: Data.FunctionMetadata.t()
        }
  @enforce_keys [:name, :module]
  defstruct [:name, :module, :code, :metadata]
end

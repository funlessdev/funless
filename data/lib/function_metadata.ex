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
    - params: a list of strings, representing the names of the parameters of the function, ordered
    - main_func: the name of the main function to be called when invoking
    - miniSL_services:
                a list of tuples, containing the methods, URLs and request/response fields of
                declared services.
                The input fields will be encoded in a JSON payload (field : value), in order.
                The output fields work the same as the :params field in this struct.
                Each input/output field is itself a tuple {field_name, field_type}.
                Currently used for the miniSL language.
                The list must contain the services in order of declaration in the function.
    - miniSL_equation:
                An array of strings, containing the function's equations (ordered).
  """
  @type param :: {String.t(), :int | :float | :bool | :string | :array}
  @type svc :: {:get | :post | :put | :delete, String.t(), [param()], [param()]}

  @type t :: %__MODULE__{
          tag: String.t(),
          capacity: integer(),
          params: [String.t()],
          main_func: String.t(),
          miniSL_services: [svc()],
          miniSL_equation: [String.t()]
        }
  defstruct tag: nil,
            capacity: -1,
            params: [],
            main_func: nil,
            miniSL_services: [],
            miniSL_equation: {}
end

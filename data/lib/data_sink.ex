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

defmodule Data.DataSink do
  @moduledoc """
    DataSink struct representing a pluggable data binding connected to a function.
    The function invocation result will be sent to each plugged data sink.

    ## Fields
      - type: the type of the data binding.
      - params: parameters needed to connect to the data sink.
  """
  @type t :: %__MODULE__{
          type: String.t(),
          params: map()
        }
  @enforce_keys [:type, :params]
  defstruct [:type, :params]
end

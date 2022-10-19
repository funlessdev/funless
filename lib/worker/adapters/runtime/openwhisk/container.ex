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

defmodule Worker.Adapters.Runtime.OpenWhisk.Container do
  @moduledoc """
    Container struct, passed to the openwhisk nif.

    ## Fields
      - name: runtime name, used with Docker runtimes
      - host: runtime IP address, used with Docker runtimes
      - port: runtime port, used with Docker runtimes
  """
  @type t :: %__MODULE__{
          name: String.t(),
          host: String.t(),
          port: String.t()
        }
  @enforce_keys [:name]
  defstruct [:name, :host, :port]
end

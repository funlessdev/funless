# Licensed to the Apache Software Foundation (ASF) under one
# or more contributor license agreements.  See the NOTICE file
# distributed with this work for additional information
# regarding copyright ownership.  The ASF licenses this file
# to you under the Apache License, Version 2.0 (the
# "License"); you may not use this file except in compliance
# with the License.  You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing,
# software distributed under the License is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
# KIND, either express or implied.  See the License for the
# specific language governing permissions and limitations
# under the License.
#

defmodule Worker.Domain.RuntimeStruct do
  @moduledoc """
    Runtime struct, passed to adapters.

    ## Fields
      - name: runtime name, used with Docker runtimes
      - host: runtime IP address, used with Docker runtimes
      - port: runtime port, used with Docker runtimes
      - wasm: WebAssembly code of a function, used with WebAssembly runtimes
  """
  @type t :: %__MODULE__{
          name: String.t(),
          host: String.t(),
          port: String.t(),
          wasm: binary()
        }
  @enforce_keys [:name]
  defstruct [:name, :host, :port, wasm: <<>>]
end

defmodule Worker.Domain.FunctionStruct do
  @moduledoc """
    Function struct, passed to adapters.

    ## Fields
      - name: function name
      - namespace: function namespace, identifies the function along with the name
      - image: base image for the function's runtime
      - code: function code, used to initialize the runtime
  """
  @type t :: %__MODULE__{
          name: String.t(),
          image: String.t(),
          code: String.t(),
          namespace: String.t()
        }
  @enforce_keys [:name, :namespace]
  defstruct [:name, :image, :code, :namespace]
end

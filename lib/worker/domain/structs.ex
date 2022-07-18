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
      - name: runtime name
      - host: runtime IP address
      - port: runtime port
  """
  @type t :: %__MODULE__{
          name: String.t(),
          host: String.t(),
          port: String.t()
        }
  @enforce_keys [:name]
  defstruct [:name, :host, :port]
end

defmodule Worker.Domain.FunctionStruct do
  @moduledoc """
    Function struct, passed to adapters.

    ## Fields
      - name: function name
      - image: base Docker image for the function's runtime
      - archive: path of the tarball containing the function's code, will be copied into runtime
      - main_file: path of the function's main file inside the runtime
  """
  @type t :: %__MODULE__{
          name: String.t(),
          image: String.t(),
          archive: String.t(),
          main_file: String.t()
        }
  @enforce_keys [:name, :image, :archive, :main_file]
  defstruct [:name, :image, :archive, :main_file]
end

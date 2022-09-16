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

defmodule Worker.Domain.Ports.Runtime.Cleaner do
  @moduledoc """
  Port for runtime removal.
  """
  alias Worker.Domain.RuntimeStruct

  @callback cleanup(RuntimeStruct.t()) :: {:ok, RuntimeStruct.t()} | {:error, any}

  @adapter :worker |> Application.compile_env!(__MODULE__) |> Keyword.fetch!(:adapter)

  @doc """
  Removes a runtime from the host system and stops tracking it in the RuntimeTracker.

  ### Parameters
  - `runtime` - The RuntimeStruct of the runtime to be removed.

  ### Returns
  - `{:ok, runtime}` - The RuntimeStruct of the runtime that was removed.
  - `{:error, err}` - An error message if the runtime could not be removed.
  """
  @spec cleanup(RuntimeStruct.t()) :: {:ok, RuntimeStruct.t()} | {:error, any}
  defdelegate cleanup(runtime), to: @adapter
end

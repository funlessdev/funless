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

defmodule Worker.Domain.Ports.Runtime.Provisioner do
  @moduledoc """
  Port for ExecutionResource creation.
  """

  alias Data.ExecutionResource
  alias Data.FunctionStruct

  @adapter :worker |> Application.compile_env!(__MODULE__) |> Keyword.fetch!(:adapter)

  @callback provision(FunctionStruct.t()) :: {:ok, ExecutionResource.t()} | {:error, any()}

  @doc """
  Provisions an ExecutionResource for the given function and module.
  It first tries to retrieve it from the cache, if missing it can either create a new one or return :code_not_found,
  depending on the adapter.

  ## Parameters
  - function: a struct with all the fields required by Data.FunctionStruct

  ## Returns
  - `{:ok, resource}` if the resource is found or created
  - `{:error, :code_not_found} if the resource was not in the cache and it won't attempt to create one.
  - `{:error, err}` if any error is encountered
  """
  @spec provision(FunctionStruct.t()) :: {:ok, ExecutionResource.t()} | {:error, any()}
  defdelegate provision(fl_function), to: @adapter
end

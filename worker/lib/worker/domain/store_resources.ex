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

defmodule Worker.Domain.StoreResource do
  @moduledoc """
  Contains functions used to store function resources on the worker.
  This should be used for raw resources. If handling initialized/compiled resources, see Worker.Domain.ProvisionResource.
  """
  alias Data.FunctionStruct
  alias Worker.Domain.Ports.RawResourceStorage

  @doc """
    Stores the given function's code as-is.

    ## Parameters
      - `%{...}`: Data.FunctionStruct, including at least the function's name, module, hash and code

    ## Returns
      - `:ok` if the resource was inserted successfully
      - `{:error, :invalid_input}` if some fields were missing, or the wrong struct was sent
      - `{:error, err}` if any other error occurred during insertion
  """
  @spec store_function(FunctionStruct.t()) :: :ok | {:error, :invalid_input} | {:error, any()}
  def store_function(%FunctionStruct{name: name, module: module, code: code, hash: hash}) do
    RawResourceStorage.insert(name, module, hash, code)
  end

  def store_function(_) do
    {:error, :invalid_input}
  end
end

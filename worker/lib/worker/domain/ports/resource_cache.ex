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

defmodule Worker.Domain.Ports.ResourceCache do
  @moduledoc """
  Port for keeping track of execution resources associated with a function, module tuple.
  """
  alias Data.ExecutionResource

  @callback get(String.t(), String.t()) :: ExecutionResource.t() | :resource_not_found
  @callback insert(String.t(), String.t(), ExecutionResource.t()) :: :ok | {:error, any}
  @callback delete(String.t(), String.t()) :: :ok | {:error, any}

  @adapter :worker |> Application.compile_env!(__MODULE__) |> Keyword.fetch!(:adapter)

  @doc """
  Retrieve the resource associated with the given function name and module.

  ### Parameters
  - `function_name` - The name of the function.
  - `module` - The module of the function.

  ### Returns
  - `ExecutionResource.t()` - The resource of the given function name if found.
  - `:resource_not_found` - If the resource is not found.
  """
  @spec get(String.t(), String.t()) :: ExecutionResource.t() | :resource_not_found
  defdelegate get(function_name, module), to: @adapter

  @doc """
  Inserts a resource into the ResourceCache associated with a function.

  ### Parameters
  - `function_name` - The name of the function to associate the resource with.
  - `module` - The module of the function.
  - `resource` - The ExecutionResource of the function to be inserted.

  ### Returns
  - `:ok` - If the resource was inserted.
  - `{:error, err}` - If an error occurred and the resource could not be inserted.
  """
  @spec insert(String.t(), String.t(), ExecutionResource.t()) :: :ok | {:error, any}
  defdelegate insert(function_name, module, resource), to: @adapter

  @doc """
  Removes the resource associated with a function from the ResourceCache.

  ### Parameters
  - `function_name` - The name of the function that the resource is associated with.
  - `module` - The module of the function.

  ### Returns
  - `:ok` - If the resource was removed.
  - `{:error, err}` - If an error occurred and the resource could not be removed.
  """
  @spec delete(String.t(), String.t()) :: :ok | {:error, any}
  defdelegate delete(function_name, module), to: @adapter
end

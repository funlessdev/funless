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

defmodule Worker.Domain.Ports.RawResourceStorage do
  @moduledoc """
  Port for storing raw binaries of resources associated with a function, module tuple.
  For storage of initialized/compiled resources, see ResourceCache.
  """

  @callback get(String.t(), String.t(), binary()) :: binary() | :resource_not_found
  @callback insert(String.t(), String.t(), binary(), binary()) :: :ok | {:error, any}
  @callback delete(String.t(), String.t(), binary()) :: :ok | {:error, any}

  @adapter :worker |> Application.compile_env!(__MODULE__) |> Keyword.fetch!(:adapter)

  @doc """
  Retrieve the resource associated with the given function name and module, and having the given hash.

  ### Parameters
  - `function_name` - The name of the function.
  - `module` - The module of the function.
  - `hash` - An hash identifying the resource.

  ### Returns
  - `binary()` - The raw resource associated with the function.
  - `:resource_not_found` - If the resource is not found.
  """
  @spec get(String.t(), String.t(), binary()) :: binary() | :resource_not_found
  defdelegate get(function_name, module, hash), to: @adapter

  @doc """
  Inserts a resource associated with a function into the RawResourceStorage.
  Keeps track of the given resource hash.

  ### Parameters
  - `function_name` - The name of the function to associate the resource with.
  - `module` - The module of the function.
  - `hash` - An hash identifying the resource.
  - `resource` - The raw resource (i.e. binary) of the function to be inserted.

  ### Returns
  - `:ok` - If the resource was inserted.
  - `{:error, err}` - If an error occurred and the resource could not be inserted.
  """
  @spec insert(String.t(), String.t(), binary(), binary()) :: :ok | {:error, any}
  defdelegate insert(function_name, module, hash, resource), to: @adapter

  @doc """
  Removes the raw resource associated with a function from the storage, if the resource matches the given hash.

  ### Parameters
  - `function_name` - The name of the function that the resource is associated with.
  - `module` - The module of the function.
  - `hash` - An hash identifying the resource.

  ### Returns
  - `:ok` - If the resource was removed.
  - `{:error, err}` - If an error occurred and the resource could not be removed.
  """
  @spec delete(String.t(), String.t(), binary()) :: :ok | {:error, any}
  defdelegate delete(function_name, module, hash), to: @adapter
end

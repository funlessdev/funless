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

defmodule Worker.Domain.Ports.RuntimeCache do
  @moduledoc """
  Port for keeping track of {function, runtime} tuples in storage.
  """
  alias Worker.Domain.RuntimeStruct

  @callback get(String.t(), String.t()) :: RuntimeStruct.t() | :runtime_not_found
  @callback insert(String.t(), String.t(), RuntimeStruct.t()) :: :ok | {:error, any}
  @callback delete(String.t(), String.t()) :: :ok | {:error, any}

  @adapter :worker |> Application.compile_env!(__MODULE__) |> Keyword.fetch!(:adapter)

  @doc """
  Retrieve the runtime associated to the given function name and namespace.

  ### Parameters
  - `function_name` - The name of the function.
  - `namespace` - The namespace of the function.

  ### Returns
  - `RuntimeStruct.t()` - The runtime of the given function name if found.
  - `:runtime_not_found` - If the runtime is not found.
  """
  @spec get(String.t(), String.t()) :: RuntimeStruct.t() | :runtime_not_found
  defdelegate get(function_name, namespace), to: @adapter

  @doc """
  Inserts a runtime into the RuntimeCache associated to a function.

  ### Parameters
  - `function_name` - The name of the function to associate the runtime with.
  - `namespace` - The namespace of the function.
  - `runtime` - The RuntimeStruct of the runtime to be inserted.

  ### Returns
  - `:ok` - If the runtime was inserted.
  - `{:error, err}` - If an error occurred and the runtime could not be inserted.
  """
  @spec insert(String.t(), String.t(), RuntimeStruct.t()) :: :ok | {:error, any}
  defdelegate insert(function_name, namespace, runtime), to: @adapter

  @doc """
  Removes the runtime associated with a function from the RuntimeCache.

  ### Parameters
  - `function_name` - The name of the function that the runtime is associated with.
  - `namespace` - The namespace of the function.

  ### Returns
  - `:ok` - If the runtime was removed.
  - `{:error, err}` - If an error occurred and the runtime could not be removed.
  """
  @spec delete(String.t(), String.t()) :: :ok | {:error, any}
  defdelegate delete(function_name, namespace), to: @adapter
end

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

defmodule Core.Domain.Ports.FunctionStorage do
  @moduledoc """
  Port for accessing and inserting functions in permanent storage.
  """
  alias Core.Domain.FunctionStruct

  @type f_name :: String.t()
  @type f_namespace :: String.t()

  @adapter :core |> Application.compile_env!(__MODULE__) |> Keyword.fetch!(:adapter)

  @callback init_database(list(atom())) :: :ok | {:error, any}
  @callback get_function(f_name, f_namespace) :: {:ok, FunctionStruct.t()} | {:error, :not_found}
  @callback insert_function(FunctionStruct.t()) :: {:ok, f_name} | {:error, {:aborted, any}}
  @callback delete_function(f_name, f_namespace) :: {:ok, f_name} | {:error, {:aborted, any}}

  @doc """
  Creates the Function database.
  Returns either :ok or {:error, err}.

  ## Parameters
    - nodes: list of nodes where the database will be created
  """
  @spec init_database(list(atom())) :: :ok | {:error, any}
  defdelegate init_database(nodes), to: @adapter

  @doc """
  Gets a function from the function storage.
  Returns the function itself as a FunctionStruct or an {:error, err} tuple.

  ## Parameters
    - function_name: Name of the function, unique in a namespace
    - function_namespace: Namespace the function is in

  """
  @spec get_function(f_name, f_namespace) :: {:ok, FunctionStruct.t()} | {:error, :not_found}
  defdelegate get_function(function_name, function_namespace), to: @adapter

  @doc """
  Inserts a function in the function storage.
  Returns the inserted function's name or an {:error, err} tuple.

  ## Parameters
    - function: a FunctionStruct

  ## Returns
    - {:ok, function_name}: if the function was successfully stored.
    - {:error, {:aborted, reason}}: if the function could not be stored.
  """
  @spec insert_function(FunctionStruct.t()) :: {:ok, f_name} | {:error, {:aborted, any}}
  defdelegate insert_function(function), to: @adapter

  @doc """
  Deletes a function in the function storage.
  Returns the deleted function's name or an {:error, err} tuple.

  ## Parameters
    - function_name: Name of the function, unique in a namespace
    - function_namespace: Namespace the function is in
  """
  @spec delete_function(f_name, f_namespace) :: {:ok, f_name} | {:error, {:aborted, any}}
  defdelegate delete_function(function_name, function_namespace), to: @adapter
end

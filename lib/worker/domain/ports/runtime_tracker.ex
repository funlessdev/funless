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

defmodule Worker.Domain.Ports.RuntimeTracker do
  @moduledoc """
  Port for keeping track of {function, runtime} tuples in storage.
  """
  alias Worker.Domain.RuntimeStruct

  @type fn_name :: String.t()
  @type runtime :: RuntimeStruct.t()

  @callback get_runtimes(fn_name) :: [runtime]

  @callback insert_runtime(fn_name, runtime) ::
              {:ok, {fn_name, runtime}} | {:error, any}

  @callback delete_runtime(fn_name, runtime) ::
              {:ok, {fn_name, runtime}} | {:error, any}

  @adapter :worker |> Application.compile_env!(__MODULE__) |> Keyword.fetch!(:adapter)

  @doc """
  Returns a list of runtimes for a given function name.

  ### Parameters
  - `function_name` - The name of the function to get runtimes for.

  ### Returns
  - `runtimes` - A list of runtimes for the given function name.
  """
  @spec get_runtimes(fn_name) :: [runtime]
  defdelegate get_runtimes(function_name), to: @adapter

  @doc """
  Inserts a runtime into the RuntimeTracker associated with a function.

  ### Parameters
  - `function_name` - The name of the function to associate the runtime with.
  - `runtime` - The RuntimeStruct of the runtime to be inserted.

  ### Returns
  - `{:ok, {function_name, runtime}}` - The function name and RuntimeStruct of the runtime that was inserted.
  - `{:error, err}` - An error message if the runtime could not be inserted.
  """
  @spec insert_runtime(fn_name, runtime) :: {:ok, {fn_name, runtime}} | {:error, any}
  defdelegate insert_runtime(function_name, runtime), to: @adapter

  @doc """
  Removes a runtime associated with a function from the RuntimeTracker.

  ### Parameters
  - `function_name` - The name of the function that the runtime is associated with.
  - `runtime` - The RuntimeStruct of the runtime to be removed.

  ### Returns
  - `{:ok, {function_name, runtime}}` - The function name and RuntimeStruct that was removed.
  - `{:error, err}` - An error message if the runtime could not be removed.
  """
  @spec delete_runtime(fn_name, runtime) :: {:ok, {fn_name, runtime}} | {:error, any}
  defdelegate delete_runtime(function_name, runtime), to: @adapter
end

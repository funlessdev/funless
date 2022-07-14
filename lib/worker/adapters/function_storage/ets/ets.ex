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

defmodule Worker.Adapters.FunctionStorage.ETS do
  @moduledoc """
  ETS adapter for storage of {function, runtime} tuples.
  """
  @behaviour Worker.Domain.Ports.FunctionStorage

  @doc """
    Returns a list of runtimes associated with the given `function_name`.

    Returns {:ok, {function_name, [list of runtimes]}} if at least a runtime is found;
    returns {:error, err} if no value is associated to the `function_name` key in the ETS table.

    ## Parameters
      - function_name: name of the function, used as key in the ETS table entries
  """
  @impl true
  def get_function_runtimes(function_name) do
    runtimes = :ets.lookup(:functions_runtimes, function_name)

    case runtimes do
      [] ->
        {:error, "no runtime found for #{function_name}"}

      tuples when is_list(tuples) ->
        t =
          tuples
          |> Enum.map(fn {_f, c} -> c end)

        {:ok, {function_name, t}}
    end
  end

  @doc """
    Inserts the  {`function_name`, `runtime`} couple in the ETS table.
    Calls the :write_server process to alter the table, does not modify it directly.

    Returns {:ok, {function_name, runtime}}.

    ## Parameters
      - function_name: name of the function, used as key in the ETS table entries
      - runtime: struct identifying the runtime
  """
  @impl true
  def insert_function_runtime(function_name, runtime) do
    GenServer.call(:write_server, {:insert, function_name, runtime})
  end

  @doc """
    Removes the  {`function_name`, `runtime`} couple from the ETS table.
    Calls the :write_server process to alter the table, does not modify it directly.

    Returns {:ok, {function_name, runtime}}.

    ## Parameters
      - function_name: name of the function, used as key in the ETS table entries
      - runtime: struct identifying the runtime
  """
  @impl true
  def delete_function_runtime(function_name, runtime) do
    GenServer.call(:write_server, {:delete, function_name, runtime})
  end
end

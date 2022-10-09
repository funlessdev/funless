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

defmodule Worker.Adapters.RuntimeCache.ETS do
  @moduledoc """
  ETS adapter for storage of {function, runtime} tuples.
  """
  @behaviour Worker.Domain.Ports.RuntimeCache

  @doc """
    Returns a list of runtimes associated with the given `function_name`.
    The list is empty if no runtime is found.

    ## Parameters
      - function_name: name of the function, used as key in the ETS table entries
  """
  @impl true
  def get_runtimes(function_name) do
    :ets.lookup(:functions_runtimes, function_name) |> Enum.map(fn {_f, c} -> c end)
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
  def insert_runtime(function_name, runtime) do
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
  def delete_runtime(function_name, runtime) do
    GenServer.call(:write_server, {:delete, function_name, runtime})
  end
end

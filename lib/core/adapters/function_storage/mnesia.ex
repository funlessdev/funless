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
defmodule Core.Adapters.FunctionStorage.Mnesia do
  @moduledoc """
  Adapter to access and insert functions on a Mnesia distributed storage.
  """
  require Logger
  alias Core.Domain.FunctionStruct
  @behaviour Core.Domain.Ports.FunctionStorage

  @impl true
  def init_database() do
    create_schema()
    |> create_table
  end

  @impl true
  def get_function(function_name, function_namespace) do
    case :mnesia.dirty_index_read(Function, {function_name, function_namespace}, :namespaced_name) do
      [] -> {:error, :not_found}
      [{Function, f, _} | _] -> {:ok, struct(FunctionStruct, f)}
    end
  end

  @impl true
  def insert_function(%FunctionStruct{name: name, namespace: namespace} = function) do
    data = fn ->
      :mnesia.write({Function, Map.from_struct(function), {name, namespace}})
    end

    :mnesia.transaction(data)
  end

  @impl true
  def delete_function(function_name, function_namespace) do
    data = fn ->
      :mnesia.delete(Function, :namespaced_name, {function_name, function_namespace})
    end

    :mnesia.transaction(data)
  end

  defp create_schema() do
    # TODO: should be all core nodes instead of just current node
    :mnesia.create_schema([node()])
  end

  defp create_table(:ok) do
    t =
      :mnesia.create_table(Function,
        attributes: [:function, :namespaced_name],
        access_mode: :read_write,
        index: [:namespaced_name],
        ram_copies: [node()]
      )

    case t do
      {_, :ok} -> :ok
      {:aborted, reason} -> {:error, {:aborted, reason}}
    end
  end

  defp create_table({:error, {_, {:already_exists, _}}}) do
    create_table(:ok)
  end

  defp create_table({:error, err}) do
    {:error, err}
  end
end

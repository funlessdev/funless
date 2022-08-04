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
  def init_database(nodes) do
    :mnesia.create_schema(nodes)
    |> create_table(nodes)
  end

  defp create_table(:ok, nodes) do
    # namespace_name acts as the primary key, and is the {function_name, function_namespace} tuple,
    # which uniquely identifies each function
    t =
      :mnesia.create_table(Function,
        attributes: [:namespace_name, :function],
        access_mode: :read_write,
        ram_copies: nodes
      )

    case t do
      {_, :ok} -> :ok
      {:aborted, reason} -> {:error, {:aborted, reason}}
    end
  end

  defp create_table({:error, {_, {:already_exists, _}}}, nodes) do
    create_table(:ok, nodes)
  end

  defp create_table({:error, err}, _) do
    {:error, err}
  end

  @impl true
  def get_function(function_name, function_namespace) do
    case :mnesia.dirty_read(Function, {function_name, function_namespace}) do
      [] -> {:error, :not_found}
      [{Function, _, f} | _] -> {:ok, struct(FunctionStruct, f)}
    end
  end

  @impl true
  def insert_function(%FunctionStruct{name: name, namespace: namespace} = function) do
    data = fn ->
      :mnesia.write({Function, {name, namespace}, Map.from_struct(function)})
    end

    case :mnesia.transaction(data) do
      {:aborted, reason} -> {:error, {:aborted, reason}}
      {_, :ok} -> {:ok, name}
    end
  end

  @impl true
  def delete_function(function_name, function_namespace) do
    data = fn ->
      :mnesia.delete({Function, {function_name, function_namespace}})
    end

    case :mnesia.transaction(data) do
      {:aborted, reason} -> {:error, {:aborted, reason}}
      {_, :ok} -> {:ok, function_name}
    end
  end
end

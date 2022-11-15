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

defmodule Core.Adapters.FunctionStore.Mnesia do
  @moduledoc """
  Adapter to access and insert functions on a Mnesia distributed storage.
  """
  require Logger
  alias Core.Domain.FunctionStruct
  @behaviour Core.Domain.Ports.FunctionStore

  @impl true
  @spec init_database(list(atom())) :: :ok | {:error, any}
  def init_database(nodes) do
    :mnesia.create_schema(nodes)
    |> create_table(nodes)
  end

  defp create_table(:ok, nodes) do
    # namespace_name acts as the primary key, and is the {function_name, function_namespace} tuple,
    # which uniquely identifies each function
    t =
      :mnesia.create_table(FunctionStruct,
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
  @spec exists?(String.t(), String.t()) :: boolean()
  def exists?(function_name, function_namespace) do
    :mnesia.dirty_all_keys(FunctionStruct)
    |> Enum.any?(&match?({^function_name, ^function_namespace}, &1))
  end

  @impl true
  @spec get_function(String.t(), String.t()) :: {:ok, FunctionStruct.t()} | {:error, :not_found}
  def get_function(function_name, function_namespace) do
    case :mnesia.dirty_read(FunctionStruct, {function_name, function_namespace}) do
      [] -> {:error, :not_found}
      [{FunctionStruct, _, f} | _] -> {:ok, struct(FunctionStruct, f)}
    end
  end

  @impl true
  @spec insert_function(FunctionStruct.t()) :: {:ok, String.t()} | {:error, {:aborted, any}}
  def insert_function(%FunctionStruct{name: name, namespace: namespace} = function) do
    data = fn ->
      :mnesia.write({FunctionStruct, {name, namespace}, Map.from_struct(function)})
    end

    case :mnesia.transaction(data) do
      {:aborted, reason} -> {:error, {:aborted, reason}}
      {_, :ok} -> {:ok, name}
    end
  end

  @impl true
  @spec delete_function(String.t(), String.t()) :: {:ok, String.t()} | {:error, {:aborted, any}}
  def delete_function(f_name, f_namespace) do
    data = fn ->
      :mnesia.delete({FunctionStruct, {f_name, f_namespace}})
    end

    case :mnesia.transaction(data) do
      {:aborted, reason} -> {:error, {:aborted, reason}}
      {_, :ok} -> {:ok, f_name}
    end
  end

  @impl true
  @spec list_functions(String.t()) :: {:ok, [String.t()]} | {:error, {:aborted, any}}
  def list_functions(namespace) do
    functions =
      :mnesia.dirty_all_keys(FunctionStruct)
      |> Enum.filter(&match?({_, ^namespace}, &1))
      |> Enum.map(fn {n, _ns} -> n end)

    {:ok, functions}
  end
end

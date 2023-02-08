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

defmodule Core.Domain.Functions do
  @moduledoc """
  The Functions context.
  """

  import Ecto.Query, warn: false
  alias Core.Repo

  alias Core.Schemas.Function
  alias Core.Schemas.Module

  @doc """
  Returns true if the function exists in a module. Otherwise false.

  ## Examples

      iex> exists_in_mod?("my_fun", "my_mod")
      true

      iex> exists_in_mod?("no_fun", "mod")
      false
  """
  def exists_in_mod?(fun_name, mod_name) do
    q =
      from(f in Function,
        join: m in Module,
        on: f.module_id == m.id,
        where: m.name == ^mod_name and f.name == ^fun_name,
        select: %Function{id: f.id}
      )

    case Repo.all(q) do
      [] -> false
      _ -> true
    end
  end

  @doc """
  Returns the list of functions.

  ## Examples

      iex> list_functions()
      [%Function{}, ...]

  """
  def list_functions do
    Repo.all(Function)
  end

  @doc """
  Gets a single function in a module.

  Returns `[]` if the Function does not exist.

  ## Examples

      iex> get_by_name_in_mod!("my_fun", "my_mod")
      [%Function{}]

      iex> get_by_name_in_mod!("no_fun", "mod")
      []

  """
  def get_by_name_in_mod!(fun_name, mod_name) do
    q =
      from(f in Function,
        join: m in Module,
        on: f.module_id == m.id,
        where: m.name == ^mod_name and f.name == ^fun_name,
        select: %Function{id: f.id, name: f.name, module_id: f.module_id}
      )

    Repo.all(q)
  end

  @doc """
  Gets a single function with code in a module.

  Returns `[]` if the Function does not exist.

  ## Examples

      iex> get_code_by_name_in_mod!("my_fun", "my_mod")
      [%Function{}]

      iex> get_code_by_name_in_mod!("no_fun", "mod")
      []
  """
  def get_code_by_name_in_mod!(fun_name, mod_name) do
    q =
      from(f in Function,
        join: m in Module,
        on: f.module_id == m.id,
        where: m.name == ^mod_name and f.name == ^fun_name,
        select: %Function{code: f.code}
      )

    Repo.all(q)
  end

  @doc """
  Gets a single function.

  Raises `Ecto.NoResultsError` if the Function does not exist.

  ## Examples

      iex> get_function!(123)
      %Function{}

      iex> get_function!(456)
      ** (Ecto.NoResultsError)
  """
  def get(fun_id), do: Repo.get!(Function, fun_id)

  @doc """
  Creates a function.

  ## Examples

      iex> create_function(%{field: value})
      {:ok, %Function{}}

      iex> create_function(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_function(attrs \\ %{}) do
    %Function{}
    |> Function.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a function.

  ## Examples

      iex> update_function(function, %{field: new_value})
      {:ok, %Function{}}

      iex> update_function(function, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_function(%Function{} = function, attrs) do
    function
    |> Function.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a function.

  ## Examples

      iex> delete_function(function)
      {:ok, %Function{}}

      iex> delete_function(function)
      {:error, %Ecto.Changeset{}}

  """
  def delete_function(%Function{} = function) do
    Repo.delete(function)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking function changes.

  ## Examples

      iex> change_function(function)
      %Ecto.Changeset{data: %Function{}}

  """
  def change_function(%Function{} = function, attrs \\ %{}) do
    Function.changeset(function, attrs)
  end
end

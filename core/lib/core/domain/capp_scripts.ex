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
defmodule Core.Domain.CAPPScripts do
  @moduledoc """
  The APPScripts context.
  """

  import Ecto.Query, warn: false
  alias Core.Repo

  alias Core.Schemas.APPScripts.CAPP

  @doc """
  Returns the list of app_scripts.

  ## Examples

      iex> list_capp_scripts()
      [%CAPP{}, ...]

  """
  def list_capp_scripts do
    Repo.all(CAPP)
  end

  @doc """
  Gets a single app_script by name.

  ## Examples

      iex> get_capp_script_by_name("some_name")
      %CAPP{}

      iex> get_capp_script_by_name("non_existent_name")
      nil
  """
  def get_capp_script_by_name(name) do
    Repo.get_by(CAPP, name: name)
  end

  @doc """
  Gets a single app_script.

  Raises `Ecto.NoResultsError` if the App script does not exist.

  ## Examples

      iex> get_capp_script!(123)
      %CAPP{}

      iex> get_capp_script!(456)
      ** (Ecto.NoResultsError)

  """
  def get_capp_script!(id), do: Repo.get!(CAPP, id)

  @doc """
  Creates a capp_script.

  ## Examples

      iex> create_capp_script(%{field: value})
      {:ok, %CAPP{}}

      iex> create_capp_script(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_capp_script(attrs \\ %{}) do
    %CAPP{}
    |> CAPP.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a capp_script.

  ## Examples

      iex> update_capp_script(app_script, %{field: new_value})
      {:ok, %CAPP{}}

      iex> update_capp_script(app_script, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_capp_script(%CAPP{} = app_script, attrs) do
    app_script
    |> CAPP.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a capp_script.

  ## Examples

      iex> delete_capp_script(app_script)
      {:ok, %CAPP{}}

      iex> delete_capp_script(app_script)
      {:error, %Ecto.Changeset{}}

  """
  def delete_capp_script(%CAPP{} = app_script) do
    Repo.delete(app_script)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking app_script changes.

  ## Examples

      iex> change_capp_script(app_script)
      %Ecto.Changeset{data: %CAPP{}}

  """
  def change_capp_script(%CAPP{} = app_script, attrs \\ %{}) do
    CAPP.changeset(app_script, attrs)
  end
end

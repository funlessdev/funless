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
defmodule Core.APPScripts do
  @moduledoc """
  The APPScripts context.
  """

  import Ecto.Query, warn: false
  alias Core.Repo

  alias Core.APPScripts.APP

  @doc """
  Returns the list of app_scripts.

  ## Examples

      iex> list_app_scripts()
      [%APP{}, ...]

  """
  def list_app_scripts do
    Repo.all(APP)
  end

  @doc """
  Gets a single app_script by name.

  ## Examples

      iex> get_app_script_by_name("some_name")
      %APP{}

      iex> get_app_script_by_name("non_existent_name")
      nil
  """
  def get_app_script_by_name(name) do
    Repo.get_by(APP, name: name)
  end

  @doc """
  Gets a single app_script.

  Raises `Ecto.NoResultsError` if the App script does not exist.

  ## Examples

      iex> get_app_script!(123)
      %APP{}

      iex> get_app_script!(456)
      ** (Ecto.NoResultsError)

  """
  def get_app_script!(id), do: Repo.get!(APP, id)

  @doc """
  Creates a app_script.

  ## Examples

      iex> create_app_script(%{field: value})
      {:ok, %APP{}}

      iex> create_app_script(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_app_script(attrs \\ %{}) do
    %APP{}
    |> APP.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a app_script.

  ## Examples

      iex> update_app_script(app_script, %{field: new_value})
      {:ok, %APP{}}

      iex> update_app_script(app_script, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_app_script(%APP{} = app_script, attrs) do
    app_script
    |> APP.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a app_script.

  ## Examples

      iex> delete_app_script(app_script)
      {:ok, %APP{}}

      iex> delete_app_script(app_script)
      {:error, %Ecto.Changeset{}}

  """
  def delete_app_script(%APP{} = app_script) do
    Repo.delete(app_script)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking app_script changes.

  ## Examples

      iex> change_app_script(app_script)
      %Ecto.Changeset{data: %APP{}}

  """
  def change_app_script(%APP{} = app_script, attrs \\ %{}) do
    APP.changeset(app_script, attrs)
  end
end

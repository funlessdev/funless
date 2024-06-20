# Copyright 2024 Giuseppe De Palma, Matteo Trentin
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

defmodule Core.FunctionsMetadata do
  @moduledoc """
  The FunctionsMetadata context.
  """

  import Ecto.Query, warn: false
  alias Core.Repo

  alias Core.Schemas.FunctionMetadata

  @doc """
  Creates a function_metadata.

  ## Examples

      iex> create_function_metadata(%{field: value})
      {:ok, %FunctionMetadata{}}

      iex> create_function_metadata(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_function_metadata(attrs \\ %{}) do
    %FunctionMetadata{}
    |> FunctionMetadata.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a function_metadata.

  ## Examples

      iex> update_function_metadata(function_metadata, %{field: new_value})
      {:ok, %FunctionMetadata{}}

      iex> update_function_metadata(function_metadata, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_function_metadata(%FunctionMetadata{} = function_metadata, attrs) do
    function_metadata
    |> FunctionMetadata.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Gets function metadata from a function's ID.

  Returns `{:ok, %FunctionMetadata}` if the metadata is found,
  `{:error, :not_found}` otherwise.
  """
  def get_function_metadata_by_function_id(function_id) do
    case Repo.get_by(FunctionMetadata, function_id: function_id) do
      nil -> {:error, :not_found}
      m -> {:ok, m}
    end
  end
end

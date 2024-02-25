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

defmodule Core.Schemas.Function do
  @moduledoc """
  The Function schema.
  """
  use Ecto.Schema
  import Ecto.Changeset

  schema "functions" do
    field(:code, :binary)
    field(:name, :string)
    field(:hash, :binary)

    timestamps()

    belongs_to(:module, Core.Schemas.Module, foreign_key: :module_id)
  end

  @doc false
  def changeset(function, attrs) do
    # only allow valid letters, numbers and underscores in the middle
    regex = ~r/^[_a-zA-Z0-9]+$/
    msg = "must contain only alphanumeric characters and underscores"

    function
    |> cast(attrs, [:name, :code, :module_id])
    |> validate_required([:name, :code, :module_id])
    |> validate_format(:name, regex, message: msg)
    |> validate_length(:name, min: 1, max: 160)
    |> insert_hash()
    |> unique_constraint(:function_module_index_constraint, name: :function_module_index)
    |> foreign_key_constraint(:module_id)
  end

  defp insert_hash(changeset) do
    case changeset do
      %Ecto.Changeset{valid?: true, changes: %{code: code}} ->
        put_change(changeset, :hash, create_hash(code))

      _ ->
        changeset
    end
  end

  defp create_hash(code) do
    :crypto.hash(:sha3_256, code)
  end
end

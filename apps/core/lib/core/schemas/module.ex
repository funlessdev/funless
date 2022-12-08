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

defmodule Core.Schemas.Module do
  @moduledoc """
  The Module schema.
  """
  use Ecto.Schema
  import Ecto.Changeset

  schema "modules" do
    field(:name, :string)

    timestamps()

    has_many(:function, Core.Schemas.Function, on_delete: :delete_all)
  end

  @doc false
  def changeset(module, attrs) do
    # only allow valid letters, numbers and underscores in the middle
    regex = ~r/^[a-zA-Z0-9]([_a-zA-Z0-9]*[a-zA-Z0-9])?$/
    msg = "must contain only alphanumeric characters and underscores"

    module
    |> cast(attrs, [:name])
    |> validate_required([:name])
    |> validate_format(:name, regex, message: msg)
    |> validate_length(:name, min: 1, max: 160)
    |> unique_constraint(:name)
  end
end

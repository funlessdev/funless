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

defmodule Core.Schemas.Function do
  @moduledoc """
  The Function schema.
  """
  use Ecto.Schema
  import Ecto.Changeset

  schema "functions" do
    field(:code, :binary)
    field(:name, :string)
    field(:module_id, :id)

    timestamps()

    belongs_to(:modules, Core.Schemas.Module)
  end

  @doc false
  def changeset(function, attrs) do
    # only allow valid letters, numbers and underscores in the middle
    regex = ~r/^[a-zA-Z0-9]([_a-zA-Z0-9]*[a-zA-Z0-9])?$/
    msg = "must contain only alphanumeric characters and underscores"

    function
    |> cast(attrs, [:name, :code])
    |> validate_required([:name, :code])
    |> validate_format(:name, regex, message: msg)
    |> validate_length(:name, min: 1, max: 160)
  end
end

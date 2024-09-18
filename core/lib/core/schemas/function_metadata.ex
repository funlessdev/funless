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

defmodule Core.Schemas.FunctionMetadata do
  @moduledoc """
  The FunctionMetadata schema.
  """
  use Ecto.Schema
  import Ecto.Changeset

  schema "function_metadata" do
    field(:capacity, :integer)
    field(:tag, :string)
    field(:main_func, :string)
    field(:params, {:array, :string})
    field(:miniSL_services, {:array, :map})
    field(:miniSL_equation, {:array, :string})

    timestamps()
    belongs_to(:function, Core.Schemas.Function, foreign_key: :function_id)
  end

  @doc false
  def changeset(function_metadata, attrs) do
    function_metadata
    |> cast(attrs, [
      :tag,
      :capacity,
      :function_id,
      :main_func,
      :params,
      :miniSL_services,
      :miniSL_equation
    ])
    |> validate_required([:function_id])
    |> unique_constraint(:function_id)
    |> foreign_key_constraint(:function_id)
  end
end

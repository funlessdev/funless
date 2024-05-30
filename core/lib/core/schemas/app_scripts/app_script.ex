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

defmodule Core.Schemas.APPScripts.APP do
  @moduledoc """
  The APP script schema.
  """
  use Ecto.Schema
  import Ecto.Changeset

  schema "app_scripts" do
    field(:name, :string)
    field(:script, :string)

    timestamps()
  end

  @doc false
  def changeset(app_script, attrs) do
    app_script
    |> cast(attrs, [:name, :script])
    |> validate_required([:name, :script])
    |> unique_constraint(:name)
  end
end

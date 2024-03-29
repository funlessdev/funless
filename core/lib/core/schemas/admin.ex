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

defmodule Core.Schemas.Admin do
  @moduledoc """
  The Admin schema
  """
  use Ecto.Schema
  import Ecto.Changeset

  schema "admins" do
    field(:name, :string)
    field(:token, :string, redact: true)

    timestamps()
  end

  @doc false
  def changeset(admin, attrs) do
    # only allow valid letters, numbers and underscores in the middle
    regex = ~r/^[_a-zA-Z0-9]+$/
    msg = "must contain only alphanumeric characters and underscores"

    admin
    |> cast(attrs, [:name, :token])
    |> validate_required([:name, :token])
    |> validate_format(:name, regex, message: msg)
    |> validate_length(:name, min: 1, max: 160)
    |> unique_constraint(:name)
  end
end

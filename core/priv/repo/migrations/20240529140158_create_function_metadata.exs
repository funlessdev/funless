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

defmodule Core.Repo.Migrations.CreateFunctionMetadata do
  use Ecto.Migration

  def change do
    create table(:function_metadata) do
      add :tag, :string
      add :capacity, :integer
      add :function_id, references(:functions, on_delete: :nothing), null: false

      timestamps()
    end

    create unique_index(:function_metadata, [:function_id])
  end
end

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

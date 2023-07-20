defmodule Core.Repo.Migrations.CreateAppScripts do
  use Ecto.Migration

  def change do
    create table(:app_scripts) do
      add(:name, :string)
      add(:script, :string)

      timestamps()
    end

    create(unique_index(:app_scripts, [:name]))
  end
end

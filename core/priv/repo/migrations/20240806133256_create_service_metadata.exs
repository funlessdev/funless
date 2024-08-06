defmodule Core.Repo.Migrations.CreateServiceMetadata do
  use Ecto.Migration

  def change do
    create table(:service_metadata) do
      add :name, :string
      add :endpoint, :string

      timestamps()
    end
  end
end

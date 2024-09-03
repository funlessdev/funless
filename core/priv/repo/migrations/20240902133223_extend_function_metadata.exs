defmodule Core.Repo.Migrations.ExtendFunctionMetadata do
  use Ecto.Migration

  def change do
    alter table(:function_metadata) do
      add :main_func, :string
      add :params, {:array, :string}
      add :miniSL_services, {:array, :map}
      add :miniSL_equation, {:array, :string}
    end
  end
end

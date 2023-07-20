defmodule Core.APPScripts.APP do
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

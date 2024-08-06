defmodule Core.ExternalServicesData.ServiceMetadata do
  use Ecto.Schema
  import Ecto.Changeset

  schema "service_metadata" do
    field :name, :string
    field :endpoint, :string

    timestamps()
  end

  @doc false
  def changeset(service_metadata, attrs) do
    service_metadata
    |> cast(attrs, [:name, :endpoint])
    |> validate_required([:name, :endpoint])
  end
end

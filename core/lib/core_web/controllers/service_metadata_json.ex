defmodule CoreWeb.ServiceMetadataJSON do
  alias Core.ExternalServicesData.ServiceMetadata

  @doc """
  Renders a list of service_metadata.
  """
  def index(%{service_metadata: service_metadata}) do
    %{data: for(service_metadata <- service_metadata, do: data(service_metadata))}
  end

  @doc """
  Renders a single service_metadata.
  """
  def show(%{service_metadata: service_metadata}) do
    %{data: data(service_metadata)}
  end

  defp data(%ServiceMetadata{} = service_metadata) do
    %{
      id: service_metadata.id,
      name: service_metadata.name,
      endpoint: service_metadata.endpoint
    }
  end
end

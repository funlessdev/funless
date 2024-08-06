defmodule CoreWeb.ServiceMetadataController do
  use CoreWeb, :controller

  alias Core.ExternalServicesData
  alias Core.ExternalServicesData.ServiceMetadata

  action_fallback(CoreWeb.FallbackController)

  def index(conn, _params) do
    service_metadata = ExternalServicesData.list_service_metadata()
    render(conn, :index, service_metadata: service_metadata)
  end

  def create(conn, %{"service_metadata" => service_metadata_params}) do
    with {:ok, %ServiceMetadata{} = service_metadata} <-
           ExternalServicesData.create_service_metadata(service_metadata_params) do
      conn
      |> put_status(:created)
      |> render(:show, service_metadata: service_metadata)
    end
  end

  def show(conn, %{"id" => id}) do
    service_metadata = ExternalServicesData.get_service_metadata!(id)
    render(conn, :show, service_metadata: service_metadata)
  end

  def update(conn, %{"id" => id, "service_metadata" => service_metadata_params}) do
    service_metadata = ExternalServicesData.get_service_metadata!(id)

    with {:ok, %ServiceMetadata{} = service_metadata} <-
           ExternalServicesData.update_service_metadata(service_metadata, service_metadata_params) do
      render(conn, :show, service_metadata: service_metadata)
    end
  end

  def delete(conn, %{"id" => id}) do
    service_metadata = ExternalServicesData.get_service_metadata!(id)

    with {:ok, %ServiceMetadata{}} <-
           ExternalServicesData.delete_service_metadata(service_metadata) do
      send_resp(conn, :no_content, "")
    end
  end
end

defmodule CoreWeb.ServiceMetadataController do
  use CoreWeb, :controller

  require Logger
  alias Core.Domain.Ports.Commands
  alias Core.ExternalServicesData
  alias Core.ExternalServicesData.ServiceMetadata

  alias Data.ServiceMetadataStruct

  alias Core.Domain.{
    Nodes
  }

  action_fallback(CoreWeb.FallbackController)

  def index(conn, _params) do
    service_metadata = ExternalServicesData.list_service_metadata()
    render(conn, :index, service_metadata: service_metadata)
  end

  def create(conn, %{"name" => svc_name, "endpoint" => svc_endpoint} = svc_metadata) do
    workers = Nodes.worker_nodes()

    svc_struct =
      struct(ServiceMetadataStruct, %{
        name: svc_name,
        endpoint: svc_endpoint
      })

    res =
      Commands.send_to_multiple_workers_sync(workers, &Commands.send_monitor_service/2, [
        svc_struct
      ])

    Logger.debug("ServiceMetadataController: create: res: #{inspect(res)}")

    # TODO no need to store this tbh, we can remove all DB stuff and just send it to the workers
    # but it might be useful to keep info about services for the core one day
    with {:ok, %ServiceMetadata{} = metadata} <-
           ExternalServicesData.create_service_metadata(svc_metadata) do
      conn
      |> put_status(:created)
      |> render(:show, service_metadata: metadata)
    end
  end

  def create(_conn, _) do
    {:error, :bad_params}
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

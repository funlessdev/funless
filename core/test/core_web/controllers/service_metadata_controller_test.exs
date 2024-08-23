defmodule CoreWeb.ServiceMetadataControllerTest do
  use CoreWeb.ConnCase

  import Core.ExternalServicesDataFixtures

  alias Core.ExternalServicesData.ServiceMetadata

  @create_attrs %{
    name: "some name",
    endpoint: "some endpoint"
  }
  @update_attrs %{
    name: "some updated name",
    endpoint: "some updated endpoint"
  }
  @invalid_attrs %{name: nil, endpoint: nil}

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  describe "index" do
    test "lists all service_metadata", %{conn: conn} do
      conn = get(conn, ~p"/api/service_metadata")
      assert json_response(conn, 200)["data"] == []
    end
  end

  describe "create service_metadata" do
    test "renders service_metadata when data is valid", %{conn: conn} do
      conn = post(conn, ~p"/api/service_metadata", service_metadata: @create_attrs)
      assert %{"id" => id} = json_response(conn, 201)["data"]

      conn = get(conn, ~p"/api/service_metadata/#{id}")

      assert %{
               "id" => ^id,
               "endpoint" => "some endpoint",
               "name" => "some name"
             } = json_response(conn, 200)["data"]
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, ~p"/api/service_metadata", service_metadata: @invalid_attrs)
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "update service_metadata" do
    setup [:create_service_metadata]

    test "renders service_metadata when data is valid", %{conn: conn, service_metadata: %ServiceMetadata{id: id} = service_metadata} do
      conn = put(conn, ~p"/api/service_metadata/#{service_metadata}", service_metadata: @update_attrs)
      assert %{"id" => ^id} = json_response(conn, 200)["data"]

      conn = get(conn, ~p"/api/service_metadata/#{id}")

      assert %{
               "id" => ^id,
               "endpoint" => "some updated endpoint",
               "name" => "some updated name"
             } = json_response(conn, 200)["data"]
    end

    test "renders errors when data is invalid", %{conn: conn, service_metadata: service_metadata} do
      conn = put(conn, ~p"/api/service_metadata/#{service_metadata}", service_metadata: @invalid_attrs)
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "delete service_metadata" do
    setup [:create_service_metadata]

    test "deletes chosen service_metadata", %{conn: conn, service_metadata: service_metadata} do
      conn = delete(conn, ~p"/api/service_metadata/#{service_metadata}")
      assert response(conn, 204)

      assert_error_sent 404, fn ->
        get(conn, ~p"/api/service_metadata/#{service_metadata}")
      end
    end
  end

  defp create_service_metadata(_) do
    service_metadata = service_metadata_fixture()
    %{service_metadata: service_metadata}
  end
end

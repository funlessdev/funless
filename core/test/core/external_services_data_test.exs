defmodule Core.ExternalServicesDataTest do
  use Core.DataCase

  alias Core.ExternalServicesData

  describe "service_metadata" do
    alias Core.ExternalServicesData.ServiceMetadata

    import Core.ExternalServicesDataFixtures

    @invalid_attrs %{name: nil, endpoint: nil}

    test "list_service_metadata/0 returns all service_metadata" do
      service_metadata = service_metadata_fixture()
      assert ExternalServicesData.list_service_metadata() == [service_metadata]
    end

    test "get_service_metadata!/1 returns the service_metadata with given id" do
      service_metadata = service_metadata_fixture()
      assert ExternalServicesData.get_service_metadata!(service_metadata.id) == service_metadata
    end

    test "create_service_metadata/1 with valid data creates a service_metadata" do
      valid_attrs = %{name: "some name", endpoint: "some endpoint"}

      assert {:ok, %ServiceMetadata{} = service_metadata} = ExternalServicesData.create_service_metadata(valid_attrs)
      assert service_metadata.name == "some name"
      assert service_metadata.endpoint == "some endpoint"
    end

    test "create_service_metadata/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = ExternalServicesData.create_service_metadata(@invalid_attrs)
    end

    test "update_service_metadata/2 with valid data updates the service_metadata" do
      service_metadata = service_metadata_fixture()
      update_attrs = %{name: "some updated name", endpoint: "some updated endpoint"}

      assert {:ok, %ServiceMetadata{} = service_metadata} = ExternalServicesData.update_service_metadata(service_metadata, update_attrs)
      assert service_metadata.name == "some updated name"
      assert service_metadata.endpoint == "some updated endpoint"
    end

    test "update_service_metadata/2 with invalid data returns error changeset" do
      service_metadata = service_metadata_fixture()
      assert {:error, %Ecto.Changeset{}} = ExternalServicesData.update_service_metadata(service_metadata, @invalid_attrs)
      assert service_metadata == ExternalServicesData.get_service_metadata!(service_metadata.id)
    end

    test "delete_service_metadata/1 deletes the service_metadata" do
      service_metadata = service_metadata_fixture()
      assert {:ok, %ServiceMetadata{}} = ExternalServicesData.delete_service_metadata(service_metadata)
      assert_raise Ecto.NoResultsError, fn -> ExternalServicesData.get_service_metadata!(service_metadata.id) end
    end

    test "change_service_metadata/1 returns a service_metadata changeset" do
      service_metadata = service_metadata_fixture()
      assert %Ecto.Changeset{} = ExternalServicesData.change_service_metadata(service_metadata)
    end
  end
end

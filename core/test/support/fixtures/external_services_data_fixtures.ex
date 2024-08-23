defmodule Core.ExternalServicesDataFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Core.ExternalServicesData` context.
  """

  @doc """
  Generate a service_metadata.
  """
  def service_metadata_fixture(attrs \\ %{}) do
    {:ok, service_metadata} =
      attrs
      |> Enum.into(%{
        name: "some name",
        endpoint: "some endpoint"
      })
      |> Core.ExternalServicesData.create_service_metadata()

    service_metadata
  end
end

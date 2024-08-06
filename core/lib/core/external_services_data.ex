defmodule Core.ExternalServicesData do
  @moduledoc """
  The ExternalServicesData context.
  """

  import Ecto.Query, warn: false
  alias Core.Repo

  alias Core.ExternalServicesData.ServiceMetadata

  @doc """
  Returns the list of service_metadata.

  ## Examples

      iex> list_service_metadata()
      [%ServiceMetadata{}, ...]

  """
  def list_service_metadata do
    Repo.all(ServiceMetadata)
  end

  @doc """
  Gets a single service_metadata.

  Raises `Ecto.NoResultsError` if the Service metadata does not exist.

  ## Examples

      iex> get_service_metadata!(123)
      %ServiceMetadata{}

      iex> get_service_metadata!(456)
      ** (Ecto.NoResultsError)

  """
  def get_service_metadata!(id), do: Repo.get!(ServiceMetadata, id)

  @doc """
  Creates a service_metadata.

  ## Examples

      iex> create_service_metadata(%{field: value})
      {:ok, %ServiceMetadata{}}

      iex> create_service_metadata(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_service_metadata(attrs \\ %{}) do
    %ServiceMetadata{}
    |> ServiceMetadata.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a service_metadata.

  ## Examples

      iex> update_service_metadata(service_metadata, %{field: new_value})
      {:ok, %ServiceMetadata{}}

      iex> update_service_metadata(service_metadata, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_service_metadata(%ServiceMetadata{} = service_metadata, attrs) do
    service_metadata
    |> ServiceMetadata.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a service_metadata.

  ## Examples

      iex> delete_service_metadata(service_metadata)
      {:ok, %ServiceMetadata{}}

      iex> delete_service_metadata(service_metadata)
      {:error, %Ecto.Changeset{}}

  """
  def delete_service_metadata(%ServiceMetadata{} = service_metadata) do
    Repo.delete(service_metadata)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking service_metadata changes.

  ## Examples

      iex> change_service_metadata(service_metadata)
      %Ecto.Changeset{data: %ServiceMetadata{}}

  """
  def change_service_metadata(%ServiceMetadata{} = service_metadata, attrs \\ %{}) do
    ServiceMetadata.changeset(service_metadata, attrs)
  end
end

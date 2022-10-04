defmodule CoreWeb.FnController do
  use CoreWeb, :controller

  alias Core.Domain.Api.FunctionRepo

  action_fallback(CoreWeb.FnFallbackController)

  def create(conn, params) do
    with {:ok, result} <- FunctionRepo.new(params) do
      render(conn, "create.json", result)
    end
  end
end

defmodule CoreWeb.FnFallbackController do
  @moduledoc """
  Translates controller action results into valid `Plug.Conn` responses.

  See `Phoenix.Controller.action_fallback/1` for more details.
  """

  use Phoenix.Controller

  def call(conn, {:error, :bad_params}) do
    conn
    |> put_status(:bad_request)
    |> put_view(CoreWeb.ErrorView)
    |> render("bad_create_request.json")
  end
end

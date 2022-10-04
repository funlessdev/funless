# Copyright 2022 Giuseppe De Palma, Matteo Trentin
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

defmodule CoreWeb.FnController do
  use CoreWeb, :controller

  alias Core.Domain.Api.FunctionRepo

  action_fallback(CoreWeb.FnFallbackController)

  def create(conn, params) do
    with {:ok, function_name} <- FunctionRepo.new(params) do
      render(conn, "create.json", function_name: function_name)
    end
  end

  def delete(conn, params) do
    with {:ok, function_name} <- FunctionRepo.delete(params) do
      render(conn, "delete.json", function_name: function_name)
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
    |> render("bad_request.json")
  end

  def call(conn, {:error, {:bad_insert, reason}}) do
    conn
    |> put_status(:service_unavailable)
    |> put_view(CoreWeb.ErrorView)
    |> render("create_db_aborted.json", reason: reason)
  end

  def call(conn, {:error, {:bad_delete, reason}}) do
    conn
    |> put_status(:service_unavailable)
    |> put_view(CoreWeb.ErrorView)
    |> render("delete_db_aborted.json", reason: reason)
  end
end

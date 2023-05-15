# Copyright 2023 Giuseppe De Palma, Matteo Trentin
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

defmodule CoreWeb.FallbackController do
  @moduledoc """
  Translates controller action results into valid `Plug.Conn` responses.

  See `Phoenix.Controller.action_fallback/1` for more details.
  """
  use CoreWeb, :controller

  # This clause handles errors returned by Ecto's insert/update/delete.
  def call(conn, {:error, %Ecto.Changeset{} = changeset}) do
    conn
    |> put_status(:unprocessable_entity)
    |> put_view(json: CoreWeb.ChangesetJSON)
    |> render(:error, changeset: changeset)
  end

  def call(conn, {:error, :not_found}) do
    conn
    |> put_status(:not_found)
    |> put_view(html: CoreWeb.ErrorHTML, json: CoreWeb.ErrorJSON)
    |> render(:"404")
  end

  def call(conn, {:error, :bad_params}) do
    conn
    |> put_status(:bad_request)
    |> put_view(html: CoreWeb.ErrorHTML, json: CoreWeb.ErrorJSON)
    |> render(:"400")
  end

  def call(conn, {:error, :conflict}) do
    conn
    |> put_status(:conflict)
    |> put_view(html: CoreWeb.ErrorHTML, json: CoreWeb.ErrorJSON)
    |> render(:"409")
  end

  def call(conn, {:error, :no_workers}) do
    res = %{errors: %{detail: "No worker available"}}

    conn
    |> put_status(:service_unavailable)
    |> json(res)
  end

  def call(conn, {:error, {:exec_error, msg}}) do
    res = %{errors: %{detail: "Error: #{msg}"}}

    conn
    |> put_status(:unprocessable_entity)
    |> json(res)
  end

  def call(conn, {:error, any}) do
    res = %{errors: %{detail: "Something went wrong: #{inspect(any)}"}}

    conn
    |> put_status(:internal_server_error)
    |> json(res)
  end
end

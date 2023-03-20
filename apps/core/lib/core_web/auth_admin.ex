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

defmodule CoreWeb.Plug.AuthenticateAdmin do
  @moduledoc """
  Plug to authenticate an admin user by token.
  """
  import Plug.Conn
  require Logger

  alias Core.Domain.Admins
  alias CoreWeb.Token

  def init(opts) do
    opts
  end

  @spec call(Plug.Conn.t(), any) :: Plug.Conn.t()
  def call(conn, _opts) do
    with ["Bearer " <> token] <- get_req_header(conn, "authorization"),
         {:ok, %{user: name}} <- Token.verify(token),
         {:ok, stored_token} <- retrieve_admin(name),
         {:ok, %{user: stored_name}} <- Token.verify(stored_token),
         true <- stored_token == token && name == stored_name do
      assign(conn, :current_user, name)
    else
      _error ->
        conn
        |> put_status(:unauthorized)
        |> Phoenix.Controller.put_view(CoreWeb.ErrorView)
        |> Phoenix.Controller.render(:"401")
        |> halt()
    end
  end

  @spec retrieve_admin(String.t()) :: {:ok, any()} | {:error, any()}
  defp retrieve_admin(name) do
    case Admins.get_admin_by_name(name) do
      nil ->
        {:error, :admin_not_found}

      user ->
        {:ok, user.token}
    end
  end
end

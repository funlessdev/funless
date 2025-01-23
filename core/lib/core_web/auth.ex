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

defmodule CoreWeb.Plug.Authenticate do
  @moduledoc """
  Plug to authenticate a user by token.
  """
  import Plug.Conn
  require Logger

  alias Core.Domain.Ports.SubjectCache
  alias Core.Domain.Subjects
  alias CoreWeb.Token

  def init(opts) do
    opts
  end

  @spec call(Plug.Conn.t(), any) :: Plug.Conn.t()
  def call(conn, _opts) do
    with ["Bearer " <> token] <- get_req_header(conn, "authorization"),
         {:ok, %{user: name}} <- Token.verify(token),
         {:ok, stored_token} <- retrieve_subject(name),
         {:ok, %{user: stored_name}} <- Token.verify(stored_token),
         true <- stored_token == token && name == stored_name do
      assign(conn, :current_user, name)
    else
      _error ->
        conn
        |> put_status(:unauthorized)
        |> Phoenix.Controller.put_view(CoreWeb.ErrorJSON)
        |> Phoenix.Controller.render(:"401")
        |> halt()
    end
  end

  @spec retrieve_subject(String.t()) :: {:ok, any()} | {:error, any()}
  defp retrieve_subject(name) do
    name
    |> SubjectCache.get()
    |> db_fallback(name)
  end

  defp db_fallback(:subject_not_found, name) do
    case Subjects.get_subject_by_name(name) do
      nil ->
        {:error, :subject_not_found}

      user ->
        SubjectCache.insert(name, user.token)
        {:ok, user.token}
    end
  end

  defp db_fallback(token, _name), do: {:ok, token}
end

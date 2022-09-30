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

defmodule Core.Adapters.Requests.Http.Server do
  @moduledoc """
  Http Server adapter to receive HTTP requests to interact with Funless Core.
  It is implemented via Bandit and handles invocation requests, which are forwarded to
  the Core API in the Domain.
  """
  alias Core.Domain.Api

  use Plug.ErrorHandler
  use Plug.Router
  require Logger

  plug(Plug.Logger, log: :debug)

  plug(Plug.Parsers,
    parsers: [:urlencoded, {:json, json_decoder: Jason}]
  )

  plug(:match)
  plug(:dispatch)

  ### Error handling

  @impl Plug.ErrorHandler
  def handle_errors(conn, %{
        kind: _kind,
        reason: %{
          exception: %Jason.DecodeError{}
        },
        stack: _stack
      }) do
    resp =
      Jason.encode!(%{
        "error" => "The provided body was not a valid JSON string"
      })

    conn = put_resp_content_type(conn, "application/json", nil)

    send_resp(
      conn,
      conn.status,
      resp
    )
  end

  @impl Plug.ErrorHandler
  def handle_errors(conn, %{
        kind: _kind,
        reason: {:timeout, {GenServer, :call, [{:worker, _} | _]}},
        stack: _stack
      }) do
    resp =
      Jason.encode!(%{
        "error" => "The invocation timed out"
      })

    conn = put_resp_content_type(conn, "application/json", nil)

    send_resp(
      conn,
      conn.status,
      resp
    )
  end

  @impl Plug.ErrorHandler
  def handle_errors(conn, %{
        kind: _kind,
        reason: _reason,
        stack: _stack
      }) do
    resp =
      Jason.encode!(%{
        "error" => "Something went wrong"
      })

    conn = put_resp_content_type(conn, "application/json", nil)

    send_resp(
      conn,
      conn.status,
      resp
    )
  end

  ### Request handling

  # Invoke request handler
  post "/invoke" do
    res = Api.Invoker.invoke(conn.body_params)
    conn = put_resp_content_type(conn, "application/json", nil)
    reply_to_client_invoke(res, conn)
  end

  # Function creation request handler
  post "/create" do
    res = Api.Function.new(conn.body_params)
    conn = put_resp_content_type(conn, "application/json", nil)
    reply_to_client(res, conn)
  end

  # Function deletion request handler
  post "/delete" do
    res = Api.Function.delete(conn.body_params)
    conn = put_resp_content_type(conn, "application/json", nil)
    reply_to_client(res, conn)
  end

  match _ do
    body = Jason.encode!(%{"error" => "Oops, this endpoint is not implemented yet"})
    conn = put_resp_content_type(conn, "application/json", nil)
    send_resp(conn, 404, body)
  end

  defp reply_to_client_invoke({:ok, result}, conn) do
    reply_to_client({:ok, %{"result" => result}}, conn)
  end

  defp reply_to_client_invoke(any, conn) do
    reply_to_client(any, conn)
  end

  defp reply_to_client({:ok, result}, conn) do
    body = Jason.encode!(result)
    send_resp(conn, 200, body)
  end

  defp reply_to_client({:error, :bad_params}, conn) do
    body = Jason.encode!(%{"error" => "Failed to perform operation: bad request"})
    send_resp(conn, 400, body)
  end

  defp reply_to_client({:error, :no_workers}, conn) do
    body = Jason.encode!(%{"error" => "Failed to invoke function: no worker available"})
    send_resp(conn, 503, body)
  end

  defp reply_to_client({:error, :worker_error}, conn) do
    body = Jason.encode!(%{"error" => "Failed to invoke function: internal worker error"})
    send_resp(conn, 500, body)
  end

  defp reply_to_client({:error, :not_found}, conn) do
    body =
      Jason.encode!(%{
        "error" => "Failed to invoke function: function not found in given namespace"
      })

    send_resp(conn, 404, body)
  end

  defp reply_to_client({:error, {:aborted, reason}}, conn) do
    body =
      Jason.encode!(%{
        "error" =>
          "Failed to perform the required operation: transaction aborted with reason #{reason}"
      })

    send_resp(conn, 500, body)
  end

  # currently unused, but could be used to handle errors in the future.
  # defp reply_to_client(_, conn) do
  #   body = Jason.encode!(%{"error" => "Something went wrong..."})
  #   send_resp(conn, 500, body)
  # end
end

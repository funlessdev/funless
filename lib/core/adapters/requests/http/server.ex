# Licensed to the Apache Software Foundation (ASF) under one
# or more contributor license agreements.  See the NOTICE file
# distributed with this work for additional information
# regarding copyright ownership.  The ASF licenses this file
# to you under the Apache License, Version 2.0 (the
# "License"); you may not use this file except in compliance
# with the License.  You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing,
# software distributed under the License is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
# KIND, either express or implied.  See the License for the
# specific language governing permissions and limitations
# under the License.
#

defmodule Core.Adapters.Requests.Http.Server do
  @moduledoc """
  Http Server adapter to receive HTTP requests to interact with Funless Core.
  It is implemented via Bandit and handles invocation requests, which are forwarded to
  the Core API in the Domain.
  """
  alias Core.Domain.Api

  use Plug.Router
  require Logger

  plug(Plug.Logger, log: :debug)

  plug(Plug.Parsers,
    parsers: [:urlencoded, {:json, json_decoder: Jason}]
  )

  plug(:match)
  plug(:dispatch)

  # Invoke request handler
  post "/invoke" do
    res = Api.invoke(conn.body_params)
    conn = put_resp_content_type(conn, "application/json", nil)
    reply_to_client(res, conn)
  end

  match _ do
    body = Jason.encode!(%{"error" => "Oops, this endpoint is not implemented yet"})
    conn = put_resp_content_type(conn, "application/json", nil)
    send_resp(conn, 404, body)
  end

  defp reply_to_client({:ok, result}, conn) do
    body = Jason.encode!(result)
    send_resp(conn, 200, body)
  end

  defp reply_to_client({:error, :no_workers}, conn) do
    body = Jason.encode!(%{"error" => "Failed to invoke function: no worker available"})
    send_resp(conn, 503, body)
  end

  defp reply_to_client({:error, :bad_params}, conn) do
    body = Jason.encode!(%{"error" => "Failed to invoke function: bad request"})
    send_resp(conn, 400, body)
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

  # currently unused, but could be used to handle errors in the future.
  defp reply_to_client(_, conn) do
    body = Jason.encode!(%{"error" => "Something went wrong..."})
    send_resp(conn, 500, body)
  end
end

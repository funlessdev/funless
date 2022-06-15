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

  plug(Plug.Parsers,
    parsers: [:urlencoded, {:json, json_decoder: Jason}]
  )

  plug(:match)
  plug(:dispatch)

  # Invoke request on _ ns: POST on _/fn/{func_name}
  get "/_/fn/:name" do
    Api.invoke(conn.params)
    |> reply_to_client(conn)
  end

  match _ do
    send_resp(conn, 404, "oops")
  end

  defp reply_to_client({:ok, name: name}, conn),
    do: send_resp(conn, 200, "Invocation of #{name} sent!")

  defp reply_to_client({:error, message: error}, conn),
    do: send_resp(conn, 503, "Error during invocation: #{error}")

  defp reply_to_client(_, conn),
    do: send_resp(conn, 500, "Something went wrong...")
end

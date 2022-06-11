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

defmodule Core.Adapters.Requests.Http.Router do
  alias Core.Domain.Api

  use Plug.Router

  plug(Plug.Parsers,
    parsers: [:urlencoded, {:json, json_decoder: Jason}]
  )

  plug(:match)
  plug(:dispatch)

  # Invoke request on _ ns: POST on _/fn/{func_name}
  post "/_/fn/:name" do
    # reply_to_client(w, conn, name)
    Api.invoke(conn.params)
    send_resp(conn, 404, "received on fn name")
  end

  match _ do
    send_resp(conn, 404, "oops")
  end

  defp reply_to_client(:no_workers, conn, _),
    do: send_resp(conn, 503, "No workers available at the moment")

  defp reply_to_client(chosen, conn, name),
    do: send_resp(conn, 200, "Sent invocation for #{name} to worker: #{chosen}")
end

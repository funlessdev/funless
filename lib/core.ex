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

defmodule Core.Router do
  use Plug.Router

  plug(Plug.Parsers,
    parsers: [:urlencoded, {:json, json_decoder: Jason}]
  )

  plug(:match)
  plug(:dispatch)

  # Invoke request on _ ns: GET on _/fn/{func_name}
  get "/_/fn/:name" do
    select_worker()
    # :name invoker on _ ns
    # |> select 1 worker for name with rust
    # |> send invoke msg to chosen worker
    # |> send response of successful invocation
    send_resp(conn, 200, "#{name} invoked")
  end

  # Invoke request on custom ns: GET on {ns}/fn/{func_name}
  get "/:ns/fn/:name" do
    send_resp(conn, 200, "#{name} invoked from #{ns} namespace")
  end

  match _ do
    send_resp(conn, 404, "oops")
  end

  defp select_worker() do
    Scheduler.select()
  end
end

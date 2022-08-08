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
defmodule Common do
  @moduledoc """
  Some common functionality for the tests.
  """
  import ExUnit.Assertions
  use Plug.Test

  @doc """
  Several asserts on the response from the http server.

  ## Parameters
  - conn: The connection to the http server to use in the assertions.
  - status: The expected status code.
  - body: The expected body.
  """
  def assert_http_response(conn, status, body) do
    assert conn.state == :sent
    assert conn.status == status
    assert get_resp_header(conn, "content-type") == ["application/json"]
    rsp_body = Jason.decode!(conn.resp_body)
    assert rsp_body == body
  end
end

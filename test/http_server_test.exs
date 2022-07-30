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
defmodule HttpServerTest do
  use ExUnit.Case, async: true
  import Mox, only: [verify_on_exit!: 1]
  use Plug.Test

  alias Core.Adapters.Requests.Http.Server

  @opts Core.Adapters.Requests.Http.Server.init([])

  setup :verify_on_exit!

  describe "Http Server invoke" do
    setup do
      Core.Commands.Mock
      |> Mox.stub_with(Core.Adapters.Commands.Test)

      Core.Cluster.Mock
      |> Mox.stub_with(Core.Adapters.Cluster.Test)

      :ok
    end

    test "should return 500 when some worker error occurs" do
      Core.Cluster.Mock |> Mox.expect(:all_nodes, fn -> [:worker@localhost] end)

      Core.Commands.Mock
      |> Mox.expect(:send_invocation_command, fn _, _ -> {:error, %{"error" => "some worker error dude"} end)

      conn = conn(:post, "/invoke", %{"namespace" => "_", "function" => "test", "args" => []})

      # Invoke the plug
      conn = Server.call(conn, @opts)

      # Assert the response and status
      assert conn.state == :sent
      assert conn.status == 500
      assert get_resp_header(conn, "content-type") == ["application/json"]
      body = Jason.decode!(conn.resp_body)
      assert body == %{"error" => "Failed to invoke function: internal worker error"}
    end

    test "should return 503 when invocation with no workers available fails" do
      conn = conn(:post, "/invoke", %{"namespace" => "_", "function" => "test", "args" => []})

      # Invoke the plug
      conn = Server.call(conn, @opts)

      # Assert the response and status
      assert conn.state == :sent
      assert conn.status == 503
      assert get_resp_header(conn, "content-type") == ["application/json"]
      body = Jason.decode!(conn.resp_body)
      assert body == %{"error" => "Failed to invoke function: no worker available"}
    end

    test "should return 200 with good request" do
      Core.Cluster.Mock |> Mox.expect(:all_nodes, fn -> [:worker@localhost] end)

      Core.Commands.Mock
      |> Mox.expect(:send_invocation_command, fn _, _ -> {:ok, %{"result" => "Hello, World!"}} end)

      # Create a test connection
      conn = conn(:post, "/invoke", %{"namespace" => "_", "function" => "hello", "args" => %{}})

      # Invoke the plug
      conn = Server.call(conn, @opts)

      # Assert the response and status
      assert conn.state == :sent
      assert conn.status == 200
      assert get_resp_header(conn, "content-type") == ["application/json"]
      body = Jason.decode!(conn.resp_body)
      assert body == %{"result" => "Hello, World!"}
    end

    test "should return 400 bad request when bad parameters" do
      # Create a test connection
      conn = conn(:post, "/invoke", %{"bad" => "arg"})

      # Invoke the plug
      conn = Server.call(conn, @opts)

      # Assert the response and status
      assert conn.state == :sent
      assert conn.status == 400
      assert get_resp_header(conn, "content-type") == ["application/json"]
      body = Jason.decode!(conn.resp_body)
      assert body == %{"error" => "Failed to invoke function: bad request"}
    end

    test "should return 400 bad request when empty invoke parameters" do
      # Create a test connection
      conn = conn(:post, "/invoke")

      # Invoke the plug
      conn = Server.call(conn, @opts)

      # Assert the response and status
      assert conn.state == :sent
      assert conn.status == 400
      assert get_resp_header(conn, "content-type") == ["application/json"]
      body = Jason.decode!(conn.resp_body)
      assert body == %{"error" => "Failed to invoke function: bad request"}
    end

    # change it with proper response
    test "should return 404 with wrong request" do
      # Create a test connection
      conn = conn(:get, "/badrequest")

      # Invoke the plug
      conn = Server.call(conn, @opts)

      # Assert the response and status
      assert conn.state == :sent
      assert conn.status == 404
      assert get_resp_header(conn, "content-type") == ["application/json"]
      body = Jason.decode!(conn.resp_body)
      assert body == %{"error" => "Oops, this endpoint is not implemented yet"}
    end
  end
end

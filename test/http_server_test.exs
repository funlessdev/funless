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

    test "invocation with no workers available fails" do
      conn = conn(:get, "/_/fn/hello")

      # Invoke the plug
      conn = Server.call(conn, @opts)

      # Assert the response and status
      assert conn.state == :sent
      assert conn.status == 503
      assert conn.resp_body == "Error during invocation: No workers available"
    end

    test "returns 200 with good request" do
      Core.Cluster.Mock |> Mox.expect(:all_nodes, fn -> [:worker@localhost] end)
      # Create a test connection
      conn = conn(:get, "/_/fn/hello_all_good")

      # Invoke the plug
      conn = Server.call(conn, @opts)

      # Assert the response and status
      assert conn.state == :sent
      assert conn.status == 200
      assert conn.resp_body == "Invocation of hello_all_good sent!"
    end

    # change it with proper response
    test "returns 404 with wrong request" do
      # Create a test connection
      conn = conn(:get, "/badrequest")

      # Invoke the plug
      conn = Server.call(conn, @opts)

      # Assert the response and status
      assert conn.state == :sent
      assert conn.status == 404
      assert conn.resp_body == "oops"
    end
  end
end

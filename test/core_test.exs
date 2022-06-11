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
# defmodule CoreTest do
#   use ExUnit.Case, async: true
#   use Plug.Test

#   @opts Core.Router.init([])

#   describe "FnApi" do
#     # as of now it only gets the first worker
#     test "get first worker when workers are present" do
#       expected = :"worker@127.0.0.1"
#       nodes = [:"worker@127.0.0.1", :"core@example.com", :"worker@ciao.it", :"extra@127.1.0.2"]
#       worker = FnApi.select_worker(nodes)
#       assert worker == expected
#     end

#     test "get :no_worker when no worker connected" do
#       expected = :no_workers
#       nodes = [:"core@example.com", :"extra@127.1.0.2"]
#       workers = FnApi.select_worker(nodes)

#       assert workers == expected
#     end

#     test "get :no_worker when empty list" do
#       expected = :no_workers
#       nodes = []
#       workers = FnApi.select_worker(nodes)

#       assert workers == expected
#     end

#     test "invoke returns no_workers when cannot invoke (no workers)" do
#       expected = :no_workers
#       nodes = []
#       res = FnApi.invoke(nodes, "_", "hello", fn _, _ -> nil end)

#       assert res == expected
#     end

#     test "invoke runs send_fun function when workers are available" do
#       w = :"worker@test.it"
#       nodes = [w]
#       res = FnApi.invoke(nodes, "_", "hello", fn _, _ -> w end)

#       assert res == w
#     end
#   end

#   describe "Router invoke" do
#     test "invocation with no workers available fails" do
#       conn = conn(:get, "/_/fn/hello")

#       # Invoke the plug
#       conn = Core.Router.call(conn, @opts)

#       # Assert the response and status
#       assert conn.state == :sent
#       assert conn.status == 503
#       assert conn.resp_body == "No workers available at the moment"
#     end

#     # change it with proper response
#     test "returns 404 with wrong request" do
#       # Create a test connection
#       conn = conn(:get, "/badrequest")

#       # Invoke the plug
#       conn = Core.Router.call(conn, @opts)

#       # Assert the response and status
#       assert conn.state == :sent
#       assert conn.status == 404
#       assert conn.resp_body == "oops"
#     end
#   end
# end

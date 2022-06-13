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

defmodule ApiTest do
  use ExUnit.Case, async: true
  alias Core.Domain.Api
  import Mox, only: [verify_on_exit!: 1]
  use Plug.Test

  # TODO: opts seems to be unused and the tests launch the real server in application.ex
  @opts Core.Adapters.Requests.Http.Router.init([])

  setup :verify_on_exit!

  # describe "main Core.Api functions" do
  #   setup do
  #     Core.Commands.Mock
  #     |> Mox.stub_with(Core.Adapters.Commands.Test)

  #     :ok
  #   end

  #   test "invoke should return {:ok, name} when no error is present" do
  #     assert Api.invoke(%{name: "test"}) == {:ok, "test"}
  #   end

  #   test "invoke should return {:error, err} when the underlying functions encounter errors" do
  #     Core.Commands.Mock
  #     |> Mox.stub(:send_invocation_command, fn _, _ -> {:error, message: "generic error"} end)

  #     assert Api.invoke(%{}) == {:error, message: "generic error"}
  #   end

  #   # TODO test error no_worker from outside
  # end

  describe "internal invoker Api" do
    setup do
      Core.Commands.Mock
      |> Mox.stub_with(Core.Adapters.Commands.Test)

      :ok
    end

    test "select_worker should return first worker when workers are present" do
      expected = :"worker@127.0.0.1"
      nodes = [:"worker@127.0.0.1", :"core@example.com", :"worker@ciao.it", :"extra@127.1.0.2"]
      worker = Core.Domain.Internal.Invoker.select_worker(nodes)
      assert worker == expected
    end

    test "select_worker should return :no_worker when no worker connected" do
      expected = :no_workers
      nodes = [:"core@example.com", :"extra@127.1.0.2"]
      workers = Core.Domain.Internal.Invoker.select_worker(nodes)

      assert workers == expected
    end

    test "select_worker should return :no_worker when empty list" do
      expected = :no_workers
      nodes = []
      workers = Core.Domain.Internal.Invoker.select_worker(nodes)

      assert workers == expected
    end

    test "invoke should return :no_workers when no workers are found" do
      nodes = []
      res = Core.Domain.Internal.Invoker.invoke(nodes, "hello_no_workers")

      assert res == {:error, [message: "No workers availble"]}
    end
  end
end

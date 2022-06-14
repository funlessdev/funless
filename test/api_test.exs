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
  import Mox, only: [verify_on_exit!: 1]
  use Plug.Test

  alias Core.Domain.Api

  setup :verify_on_exit!

  describe "main Core.Api functions" do
    setup do
      Core.Commands.Mock
      |> Mox.stub_with(Core.Adapters.Commands.Test)

      Core.Cluster.Mock
      |> Mox.stub_with(Core.Adapters.Cluster.Test)

      :ok
    end

    test "invoke should return {:ok, name} when no error is present" do
      Core.Cluster.Mock |> Mox.expect(:all_nodes, fn -> [:worker@localhost] end)
      assert Api.invoke(%{"name" => "test"}) == {:ok, name: "test"}
    end

    test "invoke should return {:error, err} when the underlying functions encounter errors" do
      Core.Cluster.Mock |> Mox.expect(:all_nodes, fn -> [:worker@localhost] end)

      Core.Commands.Mock
      |> Mox.expect(:send_invocation_command, fn _, _ -> {:error, message: "generic error"} end)

      assert Api.invoke(%{}) == {:error, message: "generic error"}
    end

    test "invoke should return {:error, no workers} when no workers are found" do
      assert Api.invoke(%{name: "test"}) == {:error, message: "No workers available"}
    end
  end

  describe "Internal Invoker" do
    setup do
      Core.Commands.Mock
      |> Mox.stub_with(Core.Adapters.Commands.Test)

      :ok
    end

    test "select_worker should return :no_workers when empty list" do
      expected = :no_workers
      w_nodes = []
      workers = Core.Domain.Internal.Invoker.select_worker(w_nodes)

      assert workers == expected
    end

    test "selec_worker should return a worker when workers are present" do
      w_nodes = [:"worker@127.0.0.1"]
      workers = Core.Domain.Internal.Invoker.select_worker(w_nodes)

      assert workers == :"worker@127.0.0.1"
    end

    test "invoke should return error no workers when no workers are found" do
      w_nodes = []
      res = Core.Domain.Internal.Invoker.invoke(w_nodes, "hello_no_workers")

      assert res == {:error, message: "No workers available"}
    end

    test "invoke should return {:ok, name} when successful" do
      w_nodes = [:"worker@127.0.0.1"]
      res = Core.Domain.Internal.Invoker.invoke(w_nodes, %{"name" => "hello"})

      assert res == {:ok, name: "hello"}
    end
  end
end

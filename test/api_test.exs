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
  alias Core.Domain.Api

  use ExUnit.Case, async: true
  import Mox, only: [verify_on_exit!: 1]
  use Plug.Test

  setup :verify_on_exit!

  describe "API invoke" do
    setup do
      Core.Commands.Mock
      |> Mox.stub_with(Core.Adapters.Commands.Test)

      Core.Cluster.Mock
      |> Mox.stub_with(Core.Adapters.Cluster.Test)

      :ok
    end

    test "invoke should return {:ok, result} when no error is present" do
      Core.Cluster.Mock |> Mox.expect(:all_nodes, fn -> [:worker@localhost] end)
      assert Api.invoke(%{"function" => "test"}) == {:ok, %{"result" => "test"}}
    end

    test "invoke should return {:error, err} when the underlying functions encounter errors" do
      Core.Cluster.Mock |> Mox.expect(:all_nodes, fn -> [:worker@localhost] end)

      Core.Commands.Mock
      |> Mox.expect(:send_invocation_command, fn _, _ -> {:error, message: "generic error"} end)

      assert Api.invoke(%{}) == {:error, message: "generic error"}
    end

    test "invoke should return {:error, no workers} when no workers are found" do
      assert Api.invoke(%{"function" => "test"}) == {:error, :no_workers}
    end

    test "invoke on node list with more than workers should only use workers" do
      Core.Cluster.Mock |> Mox.expect(:all_nodes, fn -> [:core@somewhere, :worker@localhost] end)

      Core.Commands.Mock
      |> Mox.expect(:send_invocation_command, fn worker, _ -> worker end)

      assert Api.invoke(%{"function" => "test"}) == :worker@localhost
    end

    test "invoke on node list without workers should return {:error, no workers}" do
      Core.Cluster.Mock |> Mox.expect(:all_nodes, fn -> [:core@somewhere] end)

      assert Api.invoke(%{"function" => "test"}) == {:error, :no_workers}
    end
  end
end

# Copyright 2022 Giuseppe De Palma, Matteo Trentin
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

defmodule ApiTest.InvokeTest do
  alias Core.Domain.Api.Invoker
  alias Data.FunctionStruct
  alias Data.InvokeResult

  use ExUnit.Case, async: true
  import Mox, only: [verify_on_exit!: 1]
  use Plug.Test

  setup :verify_on_exit!

  describe "API.Invoker" do
    setup do
      Core.Commands.Mock
      |> Mox.stub_with(Core.Adapters.Commands.Test)

      Core.Cluster.Mock
      |> Mox.stub_with(Core.Adapters.Cluster.Test)

      Core.FunctionStore.Mock
      |> Mox.stub_with(Core.Adapters.FunctionStore.Test)

      :ok
    end

    test "invoke should return {:ok, result} when there is at least a worker and no error occurs" do
      Core.Cluster.Mock |> Mox.expect(:all_nodes, fn -> [:worker@localhost] end)

      assert Invoker.invoke(%{"function" => "test"}) == {:ok, %InvokeResult{result: "test"}}
    end

    test "invoke should return {:error, err} when the invocation on worker encounter errors" do
      Core.Cluster.Mock |> Mox.expect(:all_nodes, fn -> [:worker@localhost] end)

      Core.Commands.Mock
      |> Mox.expect(:send_invoke, fn _, _, _, _ -> {:error, {:exec_error, "some error"}} end)

      assert Invoker.invoke(%{"function" => "f"}) == {:error, {:exec_error, "some error"}}
    end

    test "invoke should return {:error, :no_workers} when no workers are found" do
      expected = {:error, :no_workers}
      assert Invoker.invoke(%{"module" => "_", "function" => "test"}) == expected
    end

    test "invoke on node list with nodes other than workers should only use workers" do
      Core.Cluster.Mock |> Mox.expect(:all_nodes, fn -> [:core@somewhere, :worker@localhost] end)

      Core.Commands.Mock
      |> Mox.expect(:send_invoke, fn worker, _, _, _ -> {:ok, worker} end)

      assert Invoker.invoke(%{"function" => "test"}) == {:ok, :worker@localhost}
    end

    test "invoke on node list without workers should return {:error, no workers}" do
      Core.Cluster.Mock |> Mox.expect(:all_nodes, fn -> [:core@somewhere] end)

      assert Invoker.invoke(%{"function" => "test"}) == {:error, :no_workers}
    end

    test "invoke with bad parameters should return {:error, :bad_params}" do
      assert Invoker.invoke(%{"bad" => "arg"}) == {:error, :bad_params}
    end

    test "invoke on a non-existent function should return {:error, :not_found}" do
      Core.Cluster.Mock |> Mox.expect(:all_nodes, fn -> [:worker@localhost] end)
      Core.FunctionStore.Mock |> Mox.expect(:exists?, fn _, _ -> false end)

      assert Invoker.invoke(%{"function" => "hello", "module" => "ns"}) ==
               {:error, :not_found}
    end

    test "invoke with an existent function should send the invocation command using said function" do
      Core.Cluster.Mock |> Mox.expect(:all_nodes, fn -> [:worker@localhost] end)

      Core.Commands.Mock
      |> Mox.expect(:send_invoke, fn _, function, _, _ -> {:ok, %{result: function}} end)

      expected = "hello"

      assert {:ok, %{result: result}} = Invoker.invoke(%{"function" => "hello", "module" => "ns"})

      assert result == expected
    end

    test "invoke should retry the invocation with the code if the worker returns :no_code_found" do
      Core.Cluster.Mock |> Mox.expect(:all_nodes, fn -> [:worker@localhost] end)

      Core.Commands.Mock
      |> Mox.expect(:send_invoke, fn _, _, _, _ -> {:error, :code_not_found} end)

      Core.Commands.Mock
      |> Mox.expect(:send_invoke_with_code, fn _worker, function, _args ->
        {:ok, %{result: function}}
      end)

      # From FunctionStore Test
      f_in = %{"function" => "hello", "module" => "ns"}

      f_out = %FunctionStruct{
        name: "hello",
        module: "ns",
        code: "console.log(\"hello\")"
      }

      assert Invoker.invoke(f_in) == {:ok, %{result: f_out}}
    end
  end
end

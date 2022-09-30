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

      Core.FunctionStorage.Mock
      |> Mox.stub_with(Core.Adapters.FunctionStorage.Test)

      :ok
    end

    test "invoke should return {:ok, result} when there is at least a worker and no error occurs" do
      Core.Cluster.Mock |> Mox.expect(:all_nodes, fn -> [:worker@localhost] end)

      assert Api.Invoker.invoke(%{"function" => "test"}) == {:ok, %{result: "test"}}
    end

    test "invoke should return {:error, err} when the invocation on worker encounter errors" do
      Core.Cluster.Mock |> Mox.expect(:all_nodes, fn -> [:worker@localhost] end)

      Core.Commands.Mock
      |> Mox.expect(:send_invocation_command, fn _, _, _ ->
        {:error, %{}}
      end)

      assert Api.Invoker.invoke(%{"function" => "f"}) == {:error, :worker_error}
    end

    test "invoke should return {:error, no workers} when no workers are found" do
      assert Api.Invoker.invoke(%{"namespace" => "_", "function" => "test"}) ==
               {:error, :no_workers}
    end

    test "invoke on node list with nodes other than workers should only use workers" do
      Core.Cluster.Mock |> Mox.expect(:all_nodes, fn -> [:core@somewhere, :worker@localhost] end)

      Core.Commands.Mock
      |> Mox.expect(:send_invocation_command, fn worker, _, _ -> {:ok, worker} end)

      assert Api.Invoker.invoke(%{"function" => "test"}) == {:ok, :worker@localhost}
    end

    test "invoke on node list without workers should return {:error, no workers}" do
      Core.Cluster.Mock |> Mox.expect(:all_nodes, fn -> [:core@somewhere] end)

      assert Api.Invoker.invoke(%{"function" => "test"}) == {:error, :no_workers}
    end

    test "invoke with bad parameters should return {:error, :bad_params}" do
      assert Api.Invoker.invoke(%{"bad" => "arg"}) == {:error, :bad_params}
    end

    test "invoke on a non-existent function should return {:error, err}" do
      Core.Cluster.Mock |> Mox.expect(:all_nodes, fn -> [:worker@localhost] end)

      Core.FunctionStorage.Mock
      |> Mox.expect(:get_function, fn "hello", "ns" -> {:error, :not_found} end)

      assert Api.Invoker.invoke(%{"function" => "hello", "namespace" => "ns"}) ==
               {:error, :not_found}
    end

    test "invoke on an existent function should send the invocation command using said function" do
      Core.Cluster.Mock |> Mox.expect(:all_nodes, fn -> [:worker@localhost] end)

      Core.Commands.Mock
      |> Mox.expect(:send_invocation_command, fn _worker, function, _args ->
        {:ok, %{result: Map.from_struct(function)}}
      end)

      f = %{
        name: "hello",
        namespace: "ns",
        code: "console.log(\"hello\")",
        image: "nodejs"
      }

      assert Api.Invoker.invoke(%{"function" => "hello", "namespace" => "ns"}) ==
               {:ok, %{result: f}}
    end
  end
end

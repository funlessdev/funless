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

defmodule Core.InvokeTest do
  use CoreWeb.ConnCase

  alias Core.Domain.Invoker
  alias Data.{FunctionStruct, InvokeParams, InvokeResult}

  import Core.{FunctionsFixtures, ModulesFixtures}

  describe "Invoker" do
    setup do
      Core.Commands.Mock
      |> Mox.stub_with(Core.Adapters.Commands.Test)

      Core.Cluster.Mock
      |> Mox.stub_with(Core.Adapters.Cluster.Test)

      Core.DataSinks.Manager.Mock
      |> Mox.stub_with(Core.Adapters.DataSinks.Test)

      Core.Telemetry.Metrics.Mock
      |> Mox.stub_with(Core.Adapters.Telemetry.Test)

      create_function()
    end

    defp create_function do
      module = module_fixture()
      function = function_fixture(module.id)
      %{function: function, module: module}
    end

    test "invoke should return {:ok, result} when there is at least a worker and no error occurs",
         %{
           function: function,
           module: module
         } do
      Core.Cluster.Mock |> Mox.expect(:all_nodes, fn -> [:worker@localhost] end)

      pars = %InvokeParams{function: function.name, module: module.name}
      assert Invoker.invoke(pars) == {:ok, function.name}
    end

    test "invoke should return {:error, err} when the invocation on worker encounter errors",
         %{
           function: function,
           module: module
         } do
      Core.Cluster.Mock |> Mox.expect(:all_nodes, fn -> [:worker@localhost] end)

      Core.Commands.Mock
      |> Mox.expect(:send_invoke, fn _, _, _, _ -> {:error, {:exec_error, "some error"}} end)

      pars = %InvokeParams{function: function.name, module: module.name}
      assert Invoker.invoke(pars) == {:error, {:exec_error, "some error"}}
    end

    test "invoke should return {:error, :no_workers} when no workers are found", %{
      function: function,
      module: module
    } do
      expected = {:error, :no_workers}
      pars = %InvokeParams{function: function.name, module: module.name}
      assert Invoker.invoke(pars) == expected
    end

    test "invoke on node list with nodes other than workers should only use workers",
         %{
           function: function,
           module: module
         } do
      Core.Cluster.Mock |> Mox.expect(:all_nodes, fn -> [:core@somewhere, :worker@localhost] end)

      Core.Commands.Mock
      |> Mox.expect(:send_invoke, fn worker, _, _, _ -> {:ok, %InvokeResult{result: worker}} end)

      pars = %InvokeParams{function: function.name, module: module.name}
      assert Invoker.invoke(pars) == {:ok, :worker@localhost}
    end

    test "invoke on node list without workers should return {:error, no workers}",
         %{
           function: function,
           module: module
         } do
      Core.Cluster.Mock |> Mox.expect(:all_nodes, fn -> [:core@somewhere] end)

      pars = %InvokeParams{function: function.name, module: module.name}
      assert Invoker.invoke(pars) == {:error, :no_workers}
    end

    test "invoke on a non-existent function should return {:error, :not_found}" do
      Core.Cluster.Mock |> Mox.expect(:all_nodes, 0, fn -> [:worker@localhost] end)

      pars = %InvokeParams{function: "no_fun", module: "some module"}
      assert Invoker.invoke(pars) == {:error, :not_found}
    end

    test "invoke should retry the invocation with the code if the worker returns :code_not_found",
         %{
           function: function,
           module: module
         } do
      Core.Cluster.Mock |> Mox.expect(:all_nodes, fn -> [:worker@localhost] end)

      Core.Commands.Mock
      |> Mox.expect(:send_invoke, fn _, _, _, _ -> {:error, :code_not_found} end)

      Core.Commands.Mock
      |> Mox.expect(:send_invoke_with_code, fn _worker, function, _args ->
        {:ok, %InvokeResult{result: function}}
      end)

      f_out = %FunctionStruct{
        name: function.name,
        module: module.name,
        code: function.code
      }

      pars = %InvokeParams{function: function.name, module: module.name}
      assert Invoker.invoke(pars) == {:ok, f_out}
    end
  end
end

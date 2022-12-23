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

defmodule CoreWeb.FunctionControllerTest do
  use CoreWeb.ConnCase

  import Core.{FunctionsFixtures, ModulesFixtures}

  alias Core.Schemas.Function

  @create_attrs %{
    code: %Plug.Upload{path: "#{__DIR__}/../../../support/fixtures/test_code.txt"},
    name: "some_name"
  }
  @update_attrs %{
    code: %Plug.Upload{path: "#{__DIR__}/../../../support/fixtures/test_code.txt"},
    name: "some_updated_name"
  }
  @invalid_attrs %{code: nil, name: nil}

  setup %{conn: conn} do
    Core.Commands.Mock |> Mox.stub_with(Core.Adapters.Commands.Test)
    Core.Cluster.Mock |> Mox.stub_with(Core.Adapters.Cluster.Test)
    Core.Connectors.Manager.Mock |> Mox.stub_with(Core.Adapters.Connectors.Test)

    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  describe "create function" do
    test "renders function when data is valid", %{conn: conn} do
      module = module_fixture()
      conn = post(conn, Routes.function_path(conn, :create, module.name), @create_attrs)
      assert %{"name" => name} = json_response(conn, 201)["data"]

      conn = get(conn, Routes.function_path(conn, :show, module.name, name))
      assert %{"name" => "some_name"} = json_response(conn, 200)["data"]
    end

    test "renders errors when data is invalid", %{conn: conn} do
      module = module_fixture()

      conn = post(conn, Routes.function_path(conn, :create, module.name), @invalid_attrs)

      assert json_response(conn, 400)["errors"] != %{}
    end
  end

  describe "update function" do
    setup [:create_function]

    test "renders function when data is valid", %{
      conn: conn,
      function: %Function{name: function_name},
      module_name: module_name
    } do
      conn =
        put(conn, Routes.function_path(conn, :update, module_name, function_name), @update_attrs)

      assert %{"name" => new_name} = json_response(conn, 200)["data"]
      assert new_name == @update_attrs.name

      conn = get(conn, Routes.function_path(conn, :show, module_name, new_name))
      assert %{"name" => ^new_name} = json_response(conn, 200)["data"]
    end

    test "renders errors when data is invalid", %{
      conn: conn,
      function: %Function{name: name},
      module_name: module_name
    } do
      conn = put(conn, Routes.function_path(conn, :update, module_name, name), @invalid_attrs)

      assert json_response(conn, 400)["errors"] != %{}
    end
  end

  describe "delete function" do
    setup [:create_function]

    test "deletes chosen function", %{
      conn: conn,
      function: %Function{name: function_name},
      module_name: module_name
    } do
      conn = delete(conn, Routes.function_path(conn, :delete, module_name, function_name))
      assert response(conn, 204)

      conn = get(conn, Routes.function_path(conn, :show, module_name, function_name))
      assert response(conn, 404)
    end
  end

  describe "invoke function" do
    setup [:create_function]

    test "invokes function without passing args", %{
      conn: conn,
      function: %Function{name: function_name},
      module_name: module_name
    } do
      Core.Cluster.Mock |> Mox.expect(:all_nodes, fn -> [:worker@localhost] end)

      Core.Commands.Mock
      |> Mox.expect(:send_invoke, fn _, _, _, _ -> {:ok, %{result: "Hello, World!"}} end)

      conn = post(conn, Routes.function_path(conn, :invoke, module_name, function_name))
      assert response(conn, 200)
    end

    test "invokes function with args", %{
      conn: conn,
      function: %Function{name: function_name},
      module_name: module_name
    } do
      Core.Cluster.Mock |> Mox.expect(:all_nodes, fn -> [:worker@localhost] end)

      Core.Commands.Mock
      |> Mox.expect(:send_invoke, fn _, _, _, _ -> {:ok, %{result: "Hello, World!"}} end)

      conn =
        post(conn, Routes.function_path(conn, :invoke, module_name, function_name),
          args: %{name: "World"}
        )

      assert response(conn, 200)
    end

    test "invokes function when worker does not have function", %{
      conn: conn,
      function: %Function{name: function_name},
      module_name: module_name
    } do
      Core.Cluster.Mock |> Mox.expect(:all_nodes, fn -> [:worker@localhost] end)

      Core.Commands.Mock
      |> Mox.expect(:send_invoke, fn _, _, _, _ -> {:error, :code_not_found} end)

      conn = post(conn, Routes.function_path(conn, :invoke, module_name, function_name))
      assert response(conn, 200)
    end

    test "renders errors when no worker is available", %{
      conn: conn,
      function: %Function{name: function_name},
      module_name: module_name
    } do
      Core.Cluster.Mock |> Mox.expect(:all_nodes, fn -> [] end)

      conn = post(conn, Routes.function_path(conn, :invoke, module_name, function_name))
      assert response(conn, 503)
    end

    test "renders error when function does not exist", %{conn: conn} do
      Core.Cluster.Mock |> Mox.expect(:all_nodes, fn -> [:worker@localhost] end)
      conn = post(conn, Routes.function_path(conn, :invoke, "some_module", "no_function"))
      assert response(conn, 404)
    end

    test "renders error when module does not exist", %{conn: conn} do
      Core.Cluster.Mock |> Mox.expect(:all_nodes, fn -> [:worker@localhost] end)
      conn = post(conn, Routes.function_path(conn, :invoke, "no_module", "some_function"))
      assert response(conn, 404)
    end

    test "renders error when there is an exec error", %{
      conn: conn,
      function: %Function{name: function_name},
      module_name: module_name
    } do
      Core.Cluster.Mock |> Mox.expect(:all_nodes, fn -> [:worker@localhost] end)

      Core.Commands.Mock
      |> Mox.expect(:send_invoke, fn _, _, _, _ -> {:error, {:exec_error, "some reason"}} end)

      conn = post(conn, Routes.function_path(conn, :invoke, module_name, function_name))
      assert response(conn, 422)
    end
  end

  defp create_function(_) do
    module = module_fixture()
    function = function_fixture(module.id)
    %{function: function, module_name: module.name}
  end
end

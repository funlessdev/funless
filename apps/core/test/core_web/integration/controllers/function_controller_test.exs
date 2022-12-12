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
  use CoreWeb.ControllerCase

  import Core.FunctionsFixtures
  import Core.ModulesFixtures

  alias Core.Schemas.Function

  @create_attrs %{
    code: "some_code",
    name: "some_name"
  }
  @update_attrs %{
    code: "some_updated_code",
    name: "some_updated_name"
  }
  @invalid_attrs %{code: nil, name: nil}

  setup %{conn: conn} do
    Core.Commands.Mock |> Mox.stub_with(Core.Adapters.Commands.Test)
    Core.Cluster.Mock |> Mox.stub_with(Core.Adapters.Cluster.Test)

    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  describe "create function" do
    test "renders function when data is valid", %{conn: conn} do
      module = module_fixture()
      conn = post(conn, Routes.function_path(conn, :create, module.name), function: @create_attrs)
      assert %{"name" => name} = json_response(conn, 201)["data"]

      conn = get(conn, Routes.function_path(conn, :show, module.name, name))
      assert %{"name" => "some_name"} = json_response(conn, 200)["data"]
    end

    test "renders errors when data is invalid", %{conn: conn} do
      module = module_fixture()

      conn =
        post(conn, Routes.function_path(conn, :create, module.name), function: @invalid_attrs)

      assert json_response(conn, 422)["errors"] != %{}
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
        put(conn, Routes.function_path(conn, :update, module_name, function_name),
          function: @update_attrs
        )

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
      conn =
        put(conn, Routes.function_path(conn, :update, module_name, name), function: @invalid_attrs)

      assert json_response(conn, 422)["errors"] != %{}
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
  end

  defp create_function(_) do
    module = module_fixture()
    function = function_fixture(module.id)
    %{function: function, module_name: module.name}
  end
end

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
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  describe "index" do
    test "lists all functions", %{conn: conn} do
      conn = get(conn, Routes.function_path(conn, :index))
      assert json_response(conn, 200)["data"] == []
    end
  end

  describe "create function" do
    test "renders function when data is valid", %{conn: conn} do
      module = module_fixture()
      create_attrs = Map.put_new(@create_attrs, "module_id", module.id)

      conn = post(conn, Routes.function_path(conn, :create), function: create_attrs)

      assert %{"id" => id} = json_response(conn, 201)["data"]

      conn = get(conn, Routes.function_path(conn, :show, id))

      assert %{
               "id" => ^id,
               "code" => "some_code",
               "name" => "some_name"
             } = json_response(conn, 200)["data"]
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, Routes.function_path(conn, :create), function: @invalid_attrs)
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "update function" do
    setup [:create_function]

    test "renders function when data is valid", %{
      conn: conn,
      function: %Function{id: id} = function,
      module_id: module_id
    } do
      update_attrs = Map.put_new(@update_attrs, "module_id", module_id)

      conn = put(conn, Routes.function_path(conn, :update, function), function: update_attrs)
      assert %{"id" => ^id} = json_response(conn, 200)["data"]

      conn = get(conn, Routes.function_path(conn, :show, id))

      assert %{
               "id" => ^id,
               "code" => "some_updated_code",
               "name" => "some_updated_name"
             } = json_response(conn, 200)["data"]
    end

    test "renders errors when data is invalid", %{conn: conn, function: function} do
      conn = put(conn, Routes.function_path(conn, :update, function), function: @invalid_attrs)
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "delete function" do
    setup [:create_function]

    test "deletes chosen function", %{conn: conn, function: function} do
      conn = delete(conn, Routes.function_path(conn, :delete, function))
      assert response(conn, 204)

      assert_error_sent(404, fn ->
        get(conn, Routes.function_path(conn, :show, function))
      end)
    end
  end

  defp create_function(_) do
    module = module_fixture()
    function = function_fixture(module.id)
    %{function: function, module_id: module.id}
  end
end

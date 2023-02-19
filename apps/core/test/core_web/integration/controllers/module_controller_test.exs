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

defmodule CoreWeb.ModuleControllerTest do
  use CoreWeb.ConnCase

  alias Core.Domain.Subjects
  import Core.ModulesFixtures
  import Core.FunctionsFixtures
  alias Core.Schemas.Module

  @create_attrs %{
    name: "some_name"
  }
  @update_attrs %{
    name: "some_updated_name"
  }
  @invalid_attrs %{name: nil}

  setup %{conn: conn} do
    user = Subjects.get_subject_by_name("guest")

    conn =
      conn
      |> put_req_header("accept", "application/json")
      |> put_req_header("authorization", "Bearer #{user.token}")

    {:ok, conn: conn}
  end

  describe "lists" do
    test "index: lists all modules", %{conn: conn} do
      conn = get(conn, Routes.module_path(conn, :index))
      assert json_response(conn, 200)["data"] == []
    end

    test "show_functions: lists all functions in a module", %{conn: conn} do
      module = module_fixture()
      function_fixture(module.id)
      conn = get(conn, Routes.module_path(conn, :show_functions, module.name))

      assert json_response(conn, 200)["data"] ==
               %{"functions" => [%{"name" => "some_name"}], "name" => module.name}
    end
  end

  describe "create module" do
    test "renders module when data is valid", %{conn: conn} do
      conn = post(conn, Routes.module_path(conn, :create), module: @create_attrs)
      assert json_response(conn, 201)["data"] == %{"name" => @create_attrs.name}

      conn = get(conn, Routes.module_path(conn, :index))
      assert json_response(conn, 200)["data"] == [%{"name" => "some_name"}]
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, Routes.module_path(conn, :create), module: @invalid_attrs)
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "update module" do
    setup [:create_module]

    test "renders module when data is valid", %{conn: conn, module: %Module{name: name}} do
      conn = put(conn, Routes.module_path(conn, :update, name), module: @update_attrs)
      assert %{"name" => "some_updated_name"} = json_response(conn, 200)["data"]

      conn = get(conn, Routes.module_path(conn, :index))

      assert [
               %{
                 "name" => "some_updated_name"
               }
             ] = json_response(conn, 200)["data"]
    end

    test "renders errors when data is invalid", %{conn: conn, module: module} do
      conn = put(conn, Routes.module_path(conn, :update, module.name), module: @invalid_attrs)
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "delete module" do
    setup [:create_module]

    test "deletes chosen module", %{conn: conn, module: module} do
      conn = delete(conn, Routes.module_path(conn, :delete, module.name))
      assert response(conn, 204)

      conn = get(conn, Routes.module_path(conn, :index))
      assert [] == json_response(conn, 200)["data"]
    end

    test "deletes all associated functions when deleting a module", %{conn: conn, module: module} do
      function = function_fixture(module.id)
      conn = delete(conn, Routes.module_path(conn, :delete, module.name))
      assert response(conn, 204)

      conn = get(conn, Routes.function_path(conn, :show, module.name, function.name))
      assert response(conn, 404)
    end
  end

  defp create_module(_) do
    module = module_fixture()
    %{module: module}
  end
end

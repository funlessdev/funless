# Copyright 2023 Giuseppe De Palma, Matteo Trentin
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
defmodule CoreWeb.APPScriptControllerTest do
  use CoreWeb.ConnCase

  import Core.APPScriptsFixtures

  alias Core.Domain.Subjects
  alias Ecto.Adapters.SQL.Sandbox

  @create_attrs %{
    name: "some name",
    script: "some script"
  }
  # @update_attrs %{
  #   name: "some updated name",
  #   script: "some updated script"
  # }
  @invalid_attrs %{name: nil, script: nil}

  setup %{conn: conn} do
    :ok = Sandbox.checkout(Core.SubjectsRepo)
    user = Subjects.get_subject_by_name("guest")

    conn =
      conn
      |> put_req_header("accept", "application/json")
      |> put_req_header("authorization", "Bearer #{user.token}")

    {:ok, conn: conn}
  end

  describe "index" do
    test "lists all app scripts", %{conn: conn} do
      conn = get(conn, ~p"/v1/scripts/app")
      assert json_response(conn, 200)["data"] == []
    end
  end

  describe "create app_script" do
    test "renders app_script when data is valid", %{conn: conn} do
      conn = post(conn, ~p"/v1/scripts/app", app_script: @create_attrs)
      assert %{"name" => name} = json_response(conn, 201)["data"]
      conn = get(conn, ~p"/v1/scripts/app/#{name}")

      assert %{
               "name" => "some name",
               "script" => "some script"
             } = json_response(conn, 200)["data"]
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, ~p"/v1/scripts/app", app_script: @invalid_attrs)
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "get single app script" do
    setup [:create_app_script]

    test "renders app_script", %{conn: conn, app_script: %{name: name}} do
      conn = get(conn, ~p"/v1/scripts/app/#{name}")

      assert %{
               "name" => "some name",
               "script" => "some script"
             } = json_response(conn, 200)["data"]
    end
  end

  # describe "update app_script" do
  #   setup [:create_app_script]
  #
  #   test "renders app_script when data is valid", %{
  #     conn: conn,
  #     app_script: %APP{name: name} = app_script
  #   } do
  #     conn = put(conn, ~p"/v1/app/#{}", app_script: @update_attrs)
  #     assert %{"name" => ^id} = json_response(conn, 200)["data"]
  #
  #     conn = get(conn, ~p"/v1/app/#{id}")
  #
  #     assert %{
  #              "id" => ^id,
  #              "name" => "some updated name",
  #              "script" => "some updated script"
  #            } = json_response(conn, 200)["data"]
  #   end
  #
  #   test "renders errors when data is invalid", %{conn: conn, app_script: app_script} do
  #     conn = put(conn, ~p"/v1/app/#{app_script}", app_script: @invalid_attrs)
  #     assert json_response(conn, 422)["errors"] != %{}
  #   end
  # end

  # describe "delete app_script" do
  #   setup [:create_app_script]

  #   test "deletes chosen app_script", %{conn: conn, app_script: app_script} do
  #     conn = delete(conn, ~p"/v1/app/#{app_script}")
  #     assert response(conn, 204)

  #     assert_error_sent(404, fn ->
  #       get(conn, ~p"/v1/app/#{app_script}")
  #     end)
  #   end
  # end

  defp create_app_script(_) do
    app_script = app_script_fixture()
    %{app_script: app_script}
  end
end

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

defmodule CoreWeb.SubjectControllerTest do
  use CoreWeb.SubjectsConnCase

  import Core.SubjectsFixtures

  alias Core.Schemas.Subject

  @create_attrs %{
    name: "some_name",
    token: "some_token"
  }
  @update_attrs %{
    name: "some_updated_name",
    token: "some_updated_token"
  }
  @invalid_attrs %{name: nil, token: nil}

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  describe "index" do
    test "lists all subjects", %{conn: conn} do
      conn = get(conn, Routes.subject_path(conn, :index))
      assert json_response(conn, 200)["data"] == []
    end
  end

  describe "create subject" do
    test "renders subject when data is valid", %{conn: conn} do
      conn = post(conn, Routes.subject_path(conn, :create), subject: @create_attrs)
      assert %{"id" => id} = json_response(conn, 201)["data"]

      conn = get(conn, Routes.subject_path(conn, :show, id))

      assert %{
               "id" => ^id,
               "name" => "some_name",
               "token" => "some_token"
             } = json_response(conn, 200)["data"]
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, Routes.subject_path(conn, :create), subject: @invalid_attrs)
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  # describe "update subject" do
  #   setup [:create_subject]

  #   test "renders subject when data is valid", %{conn: conn, subject: %Subject{id: id} = subject} do
  #     conn = put(conn, Routes.subject_path(conn, :update, subject), subject: @update_attrs)
  #     assert %{"id" => ^id} = json_response(conn, 200)["data"]

  #     conn = get(conn, Routes.subject_path(conn, :show, id))

  #     assert %{
  #              "id" => ^id,
  #              "name" => "some updated name",
  #              "token" => "some updated token"
  #            } = json_response(conn, 200)["data"]
  #   end

  #   test "renders errors when data is invalid", %{conn: conn, subject: subject} do
  #     conn = put(conn, Routes.subject_path(conn, :update, subject), subject: @invalid_attrs)
  #     assert json_response(conn, 422)["errors"] != %{}
  #   end
  # end

  # describe "delete subject" do
  #   setup [:create_subject]

  #   test "deletes chosen subject", %{conn: conn, subject: subject} do
  #     conn = delete(conn, Routes.subject_path(conn, :delete, subject))
  #     assert response(conn, 204)

  #     assert_error_sent(404, fn ->
  #       get(conn, Routes.subject_path(conn, :show, subject))
  #     end)
  #   end
  # end

  defp create_subject(_) do
    subject = subject_fixture()
    %{subject: subject}
  end
end

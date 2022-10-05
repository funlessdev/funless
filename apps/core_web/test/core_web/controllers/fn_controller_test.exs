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

defmodule CoreWeb.FnControllerTest do
  use CoreWeb.ConnCase, async: true

  setup do
    Core.FunctionStorage.Mock
    |> Mox.stub_with(Core.Adapters.FunctionStorage.Test)

    Core.Commands.Mock
    |> Mox.stub_with(Core.Adapters.Commands.Test)

    Core.Cluster.Mock
    |> Mox.stub_with(Core.Adapters.Cluster.Test)

    :ok
  end

  describe "POST /v1/fn/invoke" do
    test "success: should return 200 with good request", %{conn: conn} do
      Core.Cluster.Mock |> Mox.expect(:all_nodes, fn -> [:worker@localhost] end)

      Core.Commands.Mock
      |> Mox.expect(:send_invocation_command, fn _, _, _ -> {:ok, %{result: "Hello, World!"}} end)

      conn = post(conn, "/v1/fn/invoke", %{namespace: "_", function: "hello", args: %{}})

      assert body = json_response(conn, 200)
      expected_keys = ["result"]

      assert_json_has_correct_keys(actual: body, expected: expected_keys)
    end

    test "error: should return 404 when the required function is not found", %{conn: conn} do
      Core.Cluster.Mock |> Mox.expect(:all_nodes, fn -> [:worker@localhost] end)
      Core.FunctionStorage.Mock |> Mox.expect(:get_function, fn _, _ -> {:error, :not_found} end)

      conn = post(conn, "/v1/fn/invoke", %{function: "hello"})

      assert body = json_response(conn, 404)
      expected_error_keys = ["detail"]
      assert_json_has_correct_keys(actual: body["errors"], expected: expected_error_keys)
    end

    test "error: should return 400 bad request when bad parameters", %{conn: conn} do
      conn = post(conn, "/v1/fn/invoke", %{bad: "param"})
      assert body = json_response(conn, 400)
      expected_error_keys = ["detail"]
      assert_json_has_correct_keys(actual: body["errors"], expected: expected_error_keys)
    end

    test "error: should returns 400 when missing parameters", %{conn: conn} do
      conn = post(conn, "/v1/fn/invoke", %{namespace: "a_ns"})

      assert body = json_response(conn, 400)
      expected_error_keys = ["detail"]

      assert_json_has_correct_keys(actual: body["errors"], expected: expected_error_keys)
    end

    test "error: should return 500 when some worker error occurs", %{conn: conn} do
      Core.Cluster.Mock |> Mox.expect(:all_nodes, fn -> [:worker@localhost] end)

      Core.Commands.Mock
      |> Mox.expect(:send_invocation_command, fn _, _, _ ->
        {:error, %{"error" => "some worker error dude"}}
      end)

      conn = post(conn, "/v1/fn/invoke", %{function: "test", code: ""})

      assert body = json_response(conn, 500)
      expected_error_keys = ["detail"]

      assert_json_has_correct_keys(actual: body["errors"], expected: expected_error_keys)
    end

    test "error: should return 503 when invocation with no workers available fails", %{conn: conn} do
      conn = post(conn, "/v1/fn/invoke", %{function: "test", code: ""})

      assert body = json_response(conn, 503)
      expected_error_keys = ["detail"]

      assert_json_has_correct_keys(actual: body["errors"], expected: expected_error_keys)
    end
  end

  describe "POST /v1/fn/create" do
    test "success: should return 200 when the creation is successful", %{conn: conn} do
      conn =
        conn
        |> post("/v1/fn/create", %{
          "name" => "hello",
          "namespace" => "ns",
          "code" => "some code"
        })

      assert body = json_response(conn, 200)
      expected_keys = ["result"]

      assert_json_has_correct_keys(actual: body, expected: expected_keys)
    end

    test "error: should returns 400 when given invalid parameters", %{conn: conn} do
      conn = post(conn, "/v1/fn/create", %{bad: "params"})

      assert body = json_response(conn, 400)
      expected_error_keys = ["detail"]

      assert_json_has_correct_keys(actual: body["errors"], expected: expected_error_keys)
    end

    test "error: should returns 400 when missing parameters", %{conn: conn} do
      conn = post(conn, "/v1/fn/create", %{name: "a_function"})

      assert body = json_response(conn, 400)
      expected_error_keys = ["detail"]

      assert_json_has_correct_keys(actual: body["errors"], expected: expected_error_keys)
    end

    test "error: should return 503 when the underlying storage transaction fails", %{conn: conn} do
      Core.FunctionStorage.Mock
      |> Mox.expect(:insert_function, fn _ -> {:error, {:aborted, "some reason"}} end)

      conn = post(conn, "/v1/fn/create", %{name: "hello", code: "some code"})

      assert body = json_response(conn, 503)
      expected_error_keys = ["detail"]

      assert_json_has_correct_keys(actual: body["errors"], expected: expected_error_keys)
    end
  end

  describe "DELETE /v1/fn/delete" do
    test "success: should return 200 when the deletion is successful", %{conn: conn} do
      conn = delete(conn, "/v1/fn/delete", %{name: "hello", namespace: "ns"})

      assert body = json_response(conn, 200)
      expected_keys = ["result"]

      assert_json_has_correct_keys(actual: body, expected: expected_keys)
    end

    test "error: should return 400 when given bad parameters", %{conn: conn} do
      conn = delete(conn, "/v1/fn/delete", %{bad: "params"})

      assert body = json_response(conn, 400)
      expected_error_keys = ["detail"]

      assert_json_has_correct_keys(actual: body["errors"], expected: expected_error_keys)
    end

    test "error: should return 400 when missing parameters", %{conn: conn} do
      conn = delete(conn, "/v1/fn/delete", %{namespace: "a_ns"})

      assert body = json_response(conn, 400)
      expected_error_keys = ["detail"]

      assert_json_has_correct_keys(actual: body["errors"], expected: expected_error_keys)
    end

    test "error: should return 503 when the underlying storage transaction fails", %{conn: conn} do
      Core.FunctionStorage.Mock
      |> Mox.expect(:delete_function, fn _, _ -> {:error, {:aborted, "some reason"}} end)

      conn = delete(conn, "/v1/fn/delete", %{name: "hello", namespace: "ns"})

      assert body = json_response(conn, 503)
      expected_error_keys = ["detail"]

      assert_json_has_correct_keys(actual: body["errors"], expected: expected_error_keys)
    end
  end
end

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

defmodule HttpServerTest.ErrorTest do
  use ExUnit.Case, async: true
  import Mox, only: [verify_on_exit!: 1]
  use Plug.Test

  alias Core.Adapters.Requests.Http.Server

  @opts Core.Adapters.Requests.Http.Server.init([])

  setup :verify_on_exit!

  describe "Http Server error handling" do
    setup do
      Core.FunctionStorage.Mock
      |> Mox.stub_with(Core.Adapters.FunctionStorage.Test)

      :ok
    end

    test "errors caused by invalid JSON strings should return a 400 code with a related message" do
      body = %{
        "name" => "hello",
        "namespace" => "ns",
        "code" => "some code",
        "image" => "nodejs"
      }

      invalid_body = Jason.encode!(body) <> ","

      expected_response =
        Jason.encode!(%{
          "error" => "The provided body was not a valid JSON string"
        })

      conn =
        conn(:post, "/create", invalid_body)
        |> put_req_header("content-type", "application/json")

      # Invoke the plug; should raise an error
      assert_raise Plug.Parsers.ParseError, ~r/^.+$/, fn ->
        _conn = Server.call(conn, @opts)
      end

      # checks if the expected response was sent, even after a crash
      assert {400, _headers, ^expected_response} = sent_resp(conn)
    end

    test "internal crashes should return a 500 code with a generic message" do
      Core.FunctionStorage.Mock
      |> Mox.expect(:insert_function, fn _ ->
        raise "some error"
        {:ok, "hello"}
      end)

      expected_response =
        Jason.encode!(%{
          "error" => "Something went wrong"
        })

      conn =
        conn(:post, "/create", %{
          "name" => "hello",
          "namespace" => "ns",
          "code" => "some code",
          "image" => "nodejs"
        })

      # Invoke the plug; should raise an error
      assert_raise Plug.Conn.WrapperError, "** (RuntimeError) some error", fn ->
        _conn = Server.call(conn, @opts)
      end

      # checks if the expected response was sent, even after a crash
      assert {500, _headers, ^expected_response} = sent_resp(conn)
    end
  end
end

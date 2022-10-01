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

defmodule HttpServerTest.FunctionStorageTest do
  use ExUnit.Case, async: true
  import Mox, only: [verify_on_exit!: 1]
  use Plug.Test

  alias Core.Adapters.Requests.Http.Server

  @opts Core.Adapters.Requests.Http.Server.init([])

  setup :verify_on_exit!

  describe "Http Server function creation/deletion" do
    setup do
      Core.FunctionStorage.Mock
      |> Mox.stub_with(Core.Adapters.FunctionStorage.Test)

      :ok
    end

    test "/create should return 200 when the creation is successful" do
      conn =
        conn(:post, "/create", %{
          "name" => "hello",
          "namespace" => "ns",
          "code" => "some code",
          "image" => "nodejs"
        })

      # Invoke the plug
      conn = Server.call(conn, @opts)

      # Assert the response and status
      Common.assert_http_response(conn, 200, %{
        "result" => "hello"
      })
    end

    test "/create should return 400 when given bad parameters" do
      conn =
        conn(:post, "/create", %{
          "name" => "hello",
          "namespace" => "ns",
          "image" => "nodejs"
        })

      # Invoke the plug
      conn = Server.call(conn, @opts)

      # Assert the response and status
      Common.assert_http_response(conn, 400, %{
        "error" => "Failed to perform operation: bad request"
      })
    end

    test "/create should return 500 when the underlying storage transaction fails" do
      Core.FunctionStorage.Mock
      |> Mox.expect(:insert_function, fn _ -> {:error, {:aborted, "some reason"}} end)

      conn =
        conn(:post, "/create", %{
          "name" => "hello",
          "namespace" => "ns",
          "image" => "nodejs",
          "code" => "some code"
        })

      # Invoke the plug
      conn = Server.call(conn, @opts)

      # Assert the response and status
      Common.assert_http_response(conn, 500, %{
        "error" =>
          "Failed to perform the required operation: transaction aborted with reason some reason"
      })
    end

    test "/delete should return 200 when the deletion is successful" do
      conn =
        conn(:post, "/delete", %{
          "name" => "hello",
          "namespace" => "ns"
        })

      # Invoke the plug
      conn = Server.call(conn, @opts)

      # Assert the response and status
      Common.assert_http_response(conn, 200, %{
        "result" => "hello"
      })
    end

    test "/delete should return 400 when given bad parameters" do
      conn =
        conn(:post, "/delete", %{
          "namespace" => "ns"
        })

      # Invoke the plug
      conn = Server.call(conn, @opts)

      # Assert the response and status
      Common.assert_http_response(conn, 400, %{
        "error" => "Failed to perform operation: bad request"
      })
    end

    test "/delete should return 500 when the underlying storage transaction fails" do
      Core.FunctionStorage.Mock
      |> Mox.expect(:delete_function, fn _, _ -> {:error, {:aborted, "some reason"}} end)

      conn =
        conn(:post, "/delete", %{
          "namespace" => "ns",
          "name" => "hello"
        })

      # Invoke the plug
      conn = Server.call(conn, @opts)

      # Assert the response and status
      Common.assert_http_response(conn, 500, %{
        "error" =>
          "Failed to perform the required operation: transaction aborted with reason some reason"
      })
    end
  end
end

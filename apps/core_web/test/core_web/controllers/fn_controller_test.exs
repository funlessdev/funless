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

  describe "POST /v1/fn/create" do
    test "error: does not create, returns 400 when given invalid params", %{conn: conn} do
      conn = post(conn, "/v1/fn/create", %{bad: "params"})

      assert body = json_response(conn, 400)

      actual_errors = body["errors"]
      refute Enum.empty?(actual_errors)

      expected_error_keys = ["detail"]

      assert expected_error_keys == Map.keys(actual_errors)
    end
  end
end

# Licensed to the Apache Software Foundation (ASF) under one
# or more contributor license agreements.  See the NOTICE file
# distributed with this work for additional information
# regarding copyright ownership.  The ASF licenses this file
# to you under the Apache License, Version 2.0 (the
# "License"); you may not use this file except in compliance
# with the License.  You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing,
# software distributed under the License is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
# KIND, either express or implied.  See the License for the
# specific language governing permissions and limitations
# under the License.
#

defmodule FunctionStorageTest do
  use ExUnit.Case, async: true
  alias Worker.Adapters.FunctionStorage.ETS
  import Mox, only: [verify_on_exit!: 1]

  setup :verify_on_exit!

  test "get_function_containers returns an error when no containers stored" do
    result = ETS.get_function_containers("test-no-container")
    assert result == {:error, "no container found for test-no-container"}
  end

  test "insert_function_container adds {function_name, container} couple to the storage" do
    container = %Worker.Domain.Container{
      host: "127.0.0.1",
      port: "8080",
      name: "test-container"
    }

    ETS.insert_function_container("test", container)

    assert ETS.get_function_containers("test") == {:ok, {"test", [container]}}
  end

  test "delete_function_container removes a {function_name, container} couple from the storage" do
    container = %Worker.Domain.Container{
      host: "127.0.0.1",
      port: "8080",
      name: "test-container"
    }

    ETS.insert_function_container("test-delete", container)

    ETS.delete_function_container("test-delete", container)

    assert ETS.get_function_containers("test-delete") ==
             {:error, "no container found for test-delete"}
  end
end

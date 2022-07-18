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
  alias(Worker.Domain.RuntimeStruct)
  import Mox, only: [verify_on_exit!: 1]

  setup :verify_on_exit!

  test "get_function_runtimes returns an error when no runtimes stored" do
    result = ETS.get_runtimes("test-no-runtime")
    assert result == []
  end

  test "insert_function_runtime adds {function_name, runtime} couple to the storage" do
    runtime = %RuntimeStruct{
      host: "127.0.0.1",
      port: "8080",
      name: "test-runtime"
    }

    ETS.insert_runtime("test", runtime)

    assert ETS.get_runtimes("test") == [runtime]
  end

  test "delete_function_runtime removes a {function_name, runtime} couple from the storage" do
    runtime = %RuntimeStruct{
      host: "127.0.0.1",
      port: "8080",
      name: "test-runtime"
    }

    ETS.insert_runtime("test-delete", runtime)

    ETS.delete_runtime("test-delete", runtime)

    assert ETS.get_runtimes("test-delete") == []
  end
end

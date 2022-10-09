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

defmodule Integration.RuntimeCacheTest do
  use ExUnit.Case
  alias Worker.Adapters.RuntimeCache.ETS
  alias Worker.Domain.RuntimeStruct
  import Mox, only: [verify_on_exit!: 1]

  setup :verify_on_exit!

  test "get_function_runtimes returns an empty list when no runtimes stored" do
    result = ETS.get_runtimes("test-no-runtime")
    assert result == []
  end

  test "insert_runtime adds {function_name, runtime} couple to the storage" do
    runtime = %RuntimeStruct{
      host: "127.0.0.1",
      port: "8080",
      name: "test-runtime"
    }

    ETS.insert_runtime("test", runtime)

    assert ETS.get_runtimes("test") == [runtime]

    ETS.delete_runtime("test", runtime)
  end

  test "multiple insert_runtime with the same function name adds the runtime to the list" do
    runtime1 = %RuntimeStruct{name: "test-runtime"}
    runtime2 = %RuntimeStruct{name: "test-runtime-2"}

    ETS.insert_runtime("test", runtime1)
    ETS.insert_runtime("test", runtime2)

    [rt, rt2] = ETS.get_runtimes("test")
    assert rt.name == "test-runtime"
    assert rt2.name == "test-runtime-2"

    ETS.delete_runtime("test", rt)
    ETS.delete_runtime("test", rt2)
  end

  test "delete_runtime removes a {function_name, runtime} couple from the storage" do
    runtime = %RuntimeStruct{
      host: "127.0.0.1",
      port: "8080",
      name: "test-runtime"
    }

    ETS.insert_runtime("test-delete", runtime)

    ETS.delete_runtime("test-delete", runtime)

    assert ETS.get_runtimes("test-delete") == []
  end

  test "delete_runtime on empty storage works" do
    rt = %RuntimeStruct{name: "name"}
    result = ETS.delete_runtime("test", rt)
    assert result == {:ok, {"test", rt}}
  end
end

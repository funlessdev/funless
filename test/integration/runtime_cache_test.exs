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
    result = ETS.get("test-no-runtime", "fake-ns")
    assert result == :runtime_not_found
  end

  test "insert adds {function_name, namespace} => runtime to the cache" do
    runtime = %RuntimeStruct{
      host: "127.0.0.1",
      port: "8080",
      name: "test-runtime"
    }

    ETS.insert("test", "ns", runtime)

    assert ETS.get("test", "ns") == runtime

    ETS.delete("test", "ns")
  end

  test "delete removes a {function_name, ns} =>, runtime couple from the storage" do
    runtime = %RuntimeStruct{
      host: "127.0.0.1",
      port: "8080",
      name: "test-runtime"
    }

    ETS.insert("test-delete", "ns", runtime)
    ETS.delete("test-delete", "ns")
    assert ETS.get("test-delete", "ns") == :runtime_not_found
  end

  test "delete on empty storage does nothing" do
    result = ETS.delete("test", "ns")
    assert result == :ok
  end
end

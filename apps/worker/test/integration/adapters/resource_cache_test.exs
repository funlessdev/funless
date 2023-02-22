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

defmodule Integration.ResourceCacheTest do
  use ExUnit.Case
  alias Data.ExecutionResource
  alias Worker.Adapters.ResourceCache
  import Mox, only: [verify_on_exit!: 1]

  setup :verify_on_exit!

  test "get returns an empty :resource_not_found when no resource stored" do
    result = ResourceCache.get("test-no-runtime", "fake-ns")
    assert result == :resource_not_found
  end

  test "insert adds {function_name, module} => resource to the cache" do
    runtime = %ExecutionResource{resource: "runtime"}

    ResourceCache.insert("test", "ns", runtime)
    assert ResourceCache.get("test", "ns") == runtime
    ResourceCache.delete("test", "ns")
  end

  test "delete removes a {function_name, ns} =>, resource couple from the storage" do
    runtime = %ExecutionResource{resource: "runtime"}
    ResourceCache.insert("test-delete", "ns", runtime)
    ResourceCache.delete("test-delete", "ns")
    assert ResourceCache.get("test-delete", "ns") == :resource_not_found
  end

  test "delete on empty storage does nothing" do
    result = ResourceCache.delete("test", "ns")
    assert result == :ok
  end
end

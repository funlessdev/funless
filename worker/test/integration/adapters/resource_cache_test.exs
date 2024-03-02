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
    result = ResourceCache.get("test-no-runtime", "fake-ns", <<0, 0, 0>>)
    assert result == :resource_not_found
  end

  test "insert adds a {function_name, module} resource to the cache" do
    runtime = %ExecutionResource{resource: "runtime"}
    hash = <<1, 1, 1>>

    ResourceCache.insert("test", "ns", hash, runtime)
    assert ResourceCache.get("test", "ns", hash) == runtime
    ResourceCache.delete("test", "ns", hash)
  end

  test "delete removes a {function_name, ns} resource couple from the storage" do
    runtime = %ExecutionResource{resource: "runtime"}
    hash = <<1, 1, 1>>

    ResourceCache.insert("test-delete", "ns", hash, runtime)
    ResourceCache.delete("test-delete", "ns", hash)
    assert ResourceCache.get("test-delete", "ns", hash) == :resource_not_found
  end

  test "delete on empty storage does nothing" do
    result = ResourceCache.delete("test", "ns", <<0, 0, 0>>)
    assert result == :ok
  end

  # we test this on the default value of 5 entries for :cachex_limit
  # to overwrite this, we would need to insert the value before the application starts
  # (since it's read directly in the ResourceCache Supervisor)
  test "oldest keys are evicted when the cache contains more than :cachex_limit entries" do
    runtime1 = %ExecutionResource{resource: "runtime1"}
    hash1 = <<1, 1, 1>>
    runtime2 = %ExecutionResource{resource: "runtime2"}
    hash2 = <<2, 2, 2>>
    runtime3 = %ExecutionResource{resource: "runtime3"}
    hash3 = <<3, 3, 3>>
    runtime4 = %ExecutionResource{resource: "runtime4"}
    hash4 = <<4, 4, 4>>
    runtime5 = %ExecutionResource{resource: "runtime5"}
    hash5 = <<5, 5, 5>>
    runtime6 = %ExecutionResource{resource: "runtime6"}
    hash6 = <<6, 6, 6>>

    ResourceCache.insert("test-threshold1", "ns", hash1, runtime1)
    :timer.sleep(200)
    ResourceCache.insert("test-threshold2", "ns", hash2, runtime2)
    :timer.sleep(200)
    ResourceCache.insert("test-threshold3", "ns", hash3, runtime3)
    :timer.sleep(200)
    ResourceCache.insert("test-threshold4", "ns", hash4, runtime4)
    :timer.sleep(200)
    ResourceCache.insert("test-threshold5", "ns", hash5, runtime5)
    :timer.sleep(200)
    ResourceCache.insert("test-threshold6", "ns", hash6, runtime6)
    :timer.sleep(2000)

    assert ResourceCache.get("test-threshold1", "ns", hash1) == :resource_not_found
    assert ResourceCache.get("test-threshold2", "ns", hash2) == :resource_not_found
    assert ResourceCache.get("test-threshold3", "ns", hash3) == runtime3
    assert ResourceCache.get("test-threshold4", "ns", hash4) == runtime4
    assert ResourceCache.get("test-threshold5", "ns", hash5) == runtime5
    assert ResourceCache.get("test-threshold6", "ns", hash6) == runtime6
  end
end

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

defmodule Integration.Adapters.RawResourceStorageTest do
  use ExUnit.Case
  alias Data.ExecutionResource
  alias Worker.Adapters.RawResourceStorage
  import Mox, only: [verify_on_exit!: 1]

  @file_prefix :worker |> Application.compile_env!(RawResourceStorage) |> Keyword.fetch!(:prefix)

  setup :verify_on_exit!

  setup_all do
    File.mkdir_p(@file_prefix)
    on_exit(fn -> File.rm_rf!(@file_prefix) end)
  end

  test "get returns an empty :resource_not_found when no resource stored" do
    result = RawResourceStorage.get("test-no-runtime", "fake-ns")
    assert result == :resource_not_found
  end

  test "insert saves a retrievable binary to the storage" do
    raw_resource = <<1, 2, 3, 4>>

    assert RawResourceStorage.insert("test", "ns", raw_resource) == :ok
    assert RawResourceStorage.get("test", "ns") == raw_resource
    RawResourceStorage.delete("test", "ns")
  end

  test "delete removes a binary from the storage" do
    runtime = %ExecutionResource{resource: "runtime"}
    RawResourceStorage.insert("test-delete", "ns", runtime)
    RawResourceStorage.delete("test-delete", "ns")
    assert RawResourceStorage.get("test-delete", "ns") == :resource_not_found
  end

  test "delete on empty storage does nothing" do
    result = RawResourceStorage.delete("test", "ns")
    assert result == :ok
  end
end

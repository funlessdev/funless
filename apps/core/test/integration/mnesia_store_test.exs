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

defmodule MnesiaStoreTest do
  use ExUnit.Case

  @tag integration_test: true

  alias Core.Adapters.FunctionStore.Mnesia
  alias Data.FunctionStruct

  setup_all :mnesia_test_setup

  setup_all do
    f = %FunctionStruct{
      name: "test-name",
      module: "ns",
      code: "console.log(\"hello\")"
    }

    %{f: f}
  end

  def mnesia_test_setup(_context) do
    Mnesia.init_database([])
    on_exit(fn -> :mnesia.stop() end)
    :ok
  end

  describe "Mnesia function storage" do
    test "exists? should return false if the function is not in the store", %{f: f} do
      refute Mnesia.exists?(f.name, f.module)
    end

    test "get_function should return {:error, :not_found} if the function is not found" do
      assert {:error, :not_found} == Mnesia.get_function("test", "_")
    end

    test "insert_function should return {:ok, name} if the function is inserted", %{f: f} do
      assert {:ok, "test-name"} == Mnesia.insert_function(f)
    end

    test "exists? should return true if the function exists", %{f: f} do
      assert Mnesia.exists?(f.name, f.module)
    end

    test "get_function should return {:ok, FunctionStruct} if the function is found", %{f: f} do
      assert {:ok, f} == Mnesia.get_function("test-name", "ns")
    end

    test "delete_function should return {:ok, function_name} when delete is successful" do
      assert {:ok, "test-name"} == Mnesia.delete_function("test-name", "ns")
    end

    test "insert_function should return {:error, {:aborted, reason}} when insert fails", %{f: f} do
      # Test with mnesia stopped so it fails to insert
      :mnesia.stop()

      assert {:error, {:aborted, _}} = Mnesia.insert_function(f)
    end
  end
end

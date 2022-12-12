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

defmodule Core.FunctionsTest do
  use Core.DataCase

  alias Core.Domain.Functions

  describe "functions" do
    alias Core.Schemas.Function

    import Core.FunctionsFixtures
    import Core.ModulesFixtures

    @invalid_attrs %{code: nil, name: nil}

    test "exists_in_mod?/2 returns true if the function exists in a module" do
      module = module_fixture()
      function = function_fixture(module.id)
      assert Functions.exists_in_mod?(function.name, module.name)
    end

    test "exists_in_mod?/2 returns false if the function does not exist in a module" do
      module = module_fixture()
      assert not Functions.exists_in_mod?("no_fun", module.name)
    end

    test "exists_in_mod?/2 returns false if the module does not exist" do
      assert not Functions.exists_in_mod?("no_fun", "no_mod")
    end

    test "list_functions/0 returns all functions" do
      module = module_fixture()
      function = function_fixture(module.id)
      assert Functions.list_functions() == [function]
    end

    test "get_by_name_in_mod!/2 returns the function with given id" do
      module = module_fixture()
      function = function_fixture(module.id)

      assert [got_function] = Functions.get_by_name_in_mod!(function.name, module.name)
      assert got_function.id == function.id
      assert got_function.name == function.name
      assert got_function.code == nil
    end

    test "get_by_name_in_mod!/2 returns [] if the function does not exist" do
      assert Functions.get_by_name_in_mod!("no_fun", "no_mod") == []
    end

    test "get_code_by_name_in_mod!/2 returns the function with the code field" do
      module = module_fixture()
      function = function_fixture(module.id)

      assert [got] = Functions.get_code_by_name_in_mod!(function.name, module.name)
      assert got.code == function.code
    end

    test "get/1 returns the function with given id" do
      module = module_fixture()
      function = function_fixture(module.id)

      assert got_function = Functions.get(function.id)
      assert got_function.id == function.id
      assert got_function.name == function.name
      assert got_function.code == function.code
    end

    test "create_function/1 with valid data creates a function" do
      module = module_fixture()
      valid_attrs = %{code: "some_code", name: "some_name", module_id: module.id}

      assert {:ok, %Function{} = function} = Functions.create_function(valid_attrs)
      assert function.code == "some_code"
      assert function.name == "some_name"
      assert function.module_id == module.id
    end

    test "create_function/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Functions.create_function(@invalid_attrs)
    end

    test "update_function/2 with valid data updates the function" do
      module = module_fixture()
      function = function_fixture(module.id)
      update_attrs = %{code: "some_updated_code", name: "some_updated_name"}

      assert {:ok, %Function{} = function} = Functions.update_function(function, update_attrs)
      assert function.code == "some_updated_code"
      assert function.name == "some_updated_name"
    end

    test "update_function/2 with invalid data returns error changeset" do
      module = module_fixture()
      function = function_fixture(module.id)
      assert {:error, %Ecto.Changeset{}} = Functions.update_function(function, @invalid_attrs)

      [got_function] = Functions.get_by_name_in_mod!(function.name, module.name)
      assert got_function.id == function.id
      assert got_function.name == function.name
    end

    test "delete_function/1 deletes the function" do
      module = module_fixture()
      function = function_fixture(module.id)
      assert {:ok, %Function{}} = Functions.delete_function(function)

      assert Functions.get_by_name_in_mod!(function.name, module.name) == []
    end

    test "change_function/1 returns a function changeset" do
      module = module_fixture()
      function = function_fixture(module.id)
      assert %Ecto.Changeset{} = Functions.change_function(function)
    end
  end
end

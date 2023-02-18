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

defmodule Core.ModulesTest do
  use Core.DataCase

  alias Core.Domain.{Functions, Modules}

  describe "modules" do
    alias Core.Schemas.Module

    import Core.ModulesFixtures
    import Core.FunctionsFixtures

    @invalid_attrs %{name: nil}

    test "list_modules/0 returns all modules" do
      module = module_fixture()
      assert Modules.list_modules() == [module]
    end

    test "get_module_by_name/1 returns the module with given name" do
      module = module_fixture()
      assert {:ok, _module} = Modules.get_module_by_name(module.name)
    end

    test "get_functions_in_module/1 returns the list of functions" do
      module = module_fixture()
      function = function_fixture(module.id)

      assert [fun] = Modules.get_functions_in_module(module.name)
      assert fun.id == function.id
      assert fun.name == function.name
    end

    test "create_module/1 with valid data creates a module" do
      valid_attrs = %{name: "some_name"}

      assert {:ok, %Module{} = module} = Modules.create_module(valid_attrs)
      assert module.name == "some_name"
    end

    test "create_module/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Modules.create_module(@invalid_attrs)
    end

    test "update_module/2 with valid data updates the module" do
      module = module_fixture()
      update_attrs = %{name: "some_updated_name"}

      assert {:ok, %Module{} = module} = Modules.update_module(module, update_attrs)
      assert module.name == "some_updated_name"
    end

    test "update_module/2 with invalid data returns error changeset" do
      module = module_fixture()
      assert {:error, %Ecto.Changeset{}} = Modules.update_module(module, @invalid_attrs)
      assert {:ok, _module} = Modules.get_module_by_name(module.name)
    end

    test "delete_module/1 deletes the module" do
      module = module_fixture()
      assert {:ok, %Module{}} = Modules.delete_module(module)
      assert {:error, :not_found} = Modules.get_module_by_name(module.name)
    end

    test "delete_module/1 also deletes all functions" do
      module = module_fixture()
      function = function_fixture(module.id)
      assert {:ok, %Module{}} = Modules.delete_module(module)

      assert [] == Functions.get_by_name_in_mod!(function.name, module.name)
    end

    test "change_module/1 returns a module changeset" do
      module = module_fixture()
      assert %Ecto.Changeset{} = Modules.change_module(module)
    end
  end
end

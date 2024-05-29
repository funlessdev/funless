# Copyright 2024 Giuseppe De Palma, Matteo Trentin
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

defmodule Core.FunctionsMetadataTest do
  alias Core.FunctionsFixtures
  alias Core.ModulesFixtures
  use Core.DataCase

  alias Core.FunctionsMetadata

  describe "function_metadata" do
    alias Core.Schemas.FunctionMetadata

    import Core.FunctionsMetadataFixtures

    @invalid_attrs %{capacity: nil, tag: nil}

    test "create_function_metadata/1 with valid data creates a function_metadata" do
      module = ModulesFixtures.module_fixture()
      function = FunctionsFixtures.function_fixture(module.id)
      valid_attrs = %{capacity: 42, tag: "some tag", function_id: function.id}

      assert {:ok, %FunctionMetadata{} = function_metadata} =
               FunctionsMetadata.create_function_metadata(valid_attrs)

      assert function_metadata.capacity == 42
      assert function_metadata.tag == "some tag"
    end

    test "create_function_metadata/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} =
               FunctionsMetadata.create_function_metadata(@invalid_attrs)
    end

    test "update_function_metadata/2 with valid data updates the function_metadata" do
      module = ModulesFixtures.module_fixture()
      function = FunctionsFixtures.function_fixture(module.id)
      function_metadata = functions_metadata_fixture(function.id)
      update_attrs = %{capacity: 43, tag: "some updated tag"}

      assert {:ok, %FunctionMetadata{} = function_metadata} =
               FunctionsMetadata.update_function_metadata(
                 function_metadata,
                 update_attrs
               )

      assert function_metadata.capacity == 43
      assert function_metadata.tag == "some updated tag"
    end

    test "update_function_metadata/2 with invalid data returns error changeset" do
      module = ModulesFixtures.module_fixture()
      function = FunctionsFixtures.function_fixture(module.id)
      function_metadata = functions_metadata_fixture(function.id)

      assert {:error, %Ecto.Changeset{}} =
               FunctionsMetadata.update_function_metadata(
                 function_metadata,
                 @invalid_attrs
               )

      assert {:ok, function_metadata} ==
               FunctionsMetadata.get_function_metadata_by_function_id(function.id)
    end
  end
end

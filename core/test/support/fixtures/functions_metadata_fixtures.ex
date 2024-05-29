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

defmodule Core.FunctionsMetadataFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Core.FunctionMetadata` context.
  """

  @doc """
  Generate a function_metadata.
  """
  def functions_metadata_fixture(function_id, attrs \\ %{}) do
    {:ok, function_metadata} =
      attrs
      |> Enum.into(%{
        capacity: 42,
        tag: "some tag",
        function_id: function_id
      })
      |> Core.FunctionsMetadata.create_function_metadata()

    function_metadata
  end
end

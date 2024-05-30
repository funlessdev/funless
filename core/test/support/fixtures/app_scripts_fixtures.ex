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
defmodule Core.APPScriptsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Core.APPScripts` context.
  """

  @doc """
  Generate a app_script.
  """
  def app_script_fixture(attrs \\ %{}) do
    {:ok, app_script} =
      attrs
      |> Enum.into(%{
        name: "some name",
        script: "some script"
      })
      |> Core.Domain.APPScripts.create_app_script()

    app_script
  end
end

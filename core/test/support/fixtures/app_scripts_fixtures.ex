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
  alias Core.Domain.APPScripts
  alias Core.Domain.Policies.Parsers.APP

  @doc """
  Generate a app_script.
  """
  def app_script_fixture(_attrs \\ %{}) do
    script = File.read!("test/support/fixtures/APP/example.yml")
    {:ok, parsed_script} = APP.parse(script)

    {:ok, app_script} =
      APPScripts.create_app_script(%{
        name: "examplescript",
        script: parsed_script |> APP.to_map()
      })

    app_script
  end
end

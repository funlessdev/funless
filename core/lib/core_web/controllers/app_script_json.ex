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
defmodule CoreWeb.APPScriptJSON do
  alias Core.Schemas.APPScripts.APP

  @doc """
  Renders a list of app_scripts.
  """
  def index(%{app_scripts: app_scripts}) do
    %{data: for(app_script <- app_scripts, do: data(app_script))}
  end

  @doc """
  Renders a single app_script.
  """
  def show(%{app_script: app_script}) do
    %{data: data(app_script)}
  end

  defp data(%APP{} = app_script) do
    %{
      id: app_script.id,
      name: app_script.name,
      script: app_script.script
    }
  end
end

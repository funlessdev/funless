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
defmodule CoreWeb.CAPPScriptJSON do
  alias Core.Schemas.APPScripts.CAPP

  @doc """
  Renders a list of capp_scripts.
  """
  def index(%{capp_scripts: capp_scripts}) do
    %{data: for(capp_script <- capp_scripts, do: data(capp_script))}
  end

  @doc """
  Renders a single capp_script.
  """
  def show(%{capp_script: capp_script}) do
    %{data: data(capp_script)}
  end

  defp data(%CAPP{} = capp_script) do
    %{
      id: capp_script.id,
      name: capp_script.name,
      script: capp_script.script
    }
  end
end

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
defmodule CoreWeb.CAPPScriptController do
  use CoreWeb, :controller

  alias Core.Domain.CAPPScripts
  alias Core.Domain.Policies.Parsers
  alias Core.Schemas.APPScripts.CAPP

  action_fallback(CoreWeb.FallbackController)

  def index(conn, _params) do
    scripts = CAPPScripts.list_capp_scripts()
    render(conn, :index, app_scripts: scripts)
  end

  def create(conn, %{"name" => script_name, "file" => %Plug.Upload{path: tmp_path}}) do
    with {:ok, capp_script_string} <- File.read(tmp_path),
         {:ok, capp_script} <- Parsers.APP.parse(capp_script_string),
         {:ok, %CAPP{} = script} <-
           CAPPScripts.create_capp_script(%{
             name: script_name,
             # TODO: change to a cAPP parser
             script: capp_script |> Parsers.APP.to_map()
           }) do
      conn
      |> put_status(:created)
      |> render(:show, app_script: script)
    end
  end

  def create(_, _) do
    {:error, :bad_params}
  end

  def show(conn, %{"app_name" => name}) do
    script = CAPPScripts.get_capp_script_by_name(name)
    render(conn, :show, capp_script: script)
  end

  def update(conn, %{"id" => id, "capp_script" => capp_script_params}) do
    capp_script = CAPPScripts.get_capp_script!(id)

    with {:ok, %CAPP{} = capp_script} <-
           CAPPScripts.update_capp_script(capp_script, capp_script_params) do
      render(conn, :show, app_script: capp_script)
    end
  end

  def delete(conn, %{"id" => id}) do
    script = CAPPScripts.get_capp_script!(id)

    with {:ok, %CAPP{}} <- CAPPScripts.delete_capp_script(script) do
      send_resp(conn, :no_content, "")
    end
  end
end

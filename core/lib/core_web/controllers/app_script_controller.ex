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
defmodule CoreWeb.APPScriptController do
  use CoreWeb, :controller

  alias Core.Domain.APPScripts
  alias Core.Schemas.APPScripts.APP

  action_fallback(CoreWeb.FallbackController)

  def index(conn, _params) do
    app_scripts = APPScripts.list_app_scripts()
    render(conn, :index, app_scripts: app_scripts)
  end

  # TODO: parse APP script on creation and store struct as map
  def create(conn, %{"app_script" => app_script_params}) do
    with {:ok, %APP{} = app_script} <- APPScripts.create_app_script(app_script_params) do
      conn
      |> put_status(:created)
      |> render(:show, app_script: app_script)
    end
  end

  def show(conn, %{"app_name" => name}) do
    app_script = APPScripts.get_app_script_by_name(name)
    render(conn, :show, app_script: app_script)
  end

  def update(conn, %{"id" => id, "app_script" => app_script_params}) do
    app_script = APPScripts.get_app_script!(id)

    with {:ok, %APP{} = app_script} <- APPScripts.update_app_script(app_script, app_script_params) do
      render(conn, :show, app_script: app_script)
    end
  end

  def delete(conn, %{"id" => id}) do
    app_script = APPScripts.get_app_script!(id)

    with {:ok, %APP{}} <- APPScripts.delete_app_script(app_script) do
      send_resp(conn, :no_content, "")
    end
  end
end

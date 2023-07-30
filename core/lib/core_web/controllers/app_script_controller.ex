defmodule CoreWeb.APPScriptController do
  use CoreWeb, :controller

  alias Core.APPScripts
  alias Core.APPScripts.APP

  action_fallback(CoreWeb.FallbackController)

  def index(conn, _params) do
    app_scripts = APPScripts.list_app_scripts()
    render(conn, :index, app_scripts: app_scripts)
  end

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

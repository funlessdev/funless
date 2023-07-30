defmodule CoreWeb.APPScriptJSON do
  alias Core.APPScripts.APP

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

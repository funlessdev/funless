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
      |> Core.APPScripts.create_app_script()

    app_script
  end
end

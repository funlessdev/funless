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
defmodule Core.APPScriptsTest do
  use Core.DataCase

  alias Core.Domain.APPScripts

  describe "app_scripts" do
    alias Core.Schemas.APPScripts.APP

    import Core.APPScriptsFixtures

    @invalid_attrs %{name: nil, script: nil}

    test "list_app_scripts/0 returns all app_scripts, with string keys instead of atoms" do
      app_script = app_script_fixture()
      %{script: script_content} = app_script

      assert APPScripts.list_app_scripts() == [
               app_script
               |> Map.put(:script, script_content |> Jason.encode!() |> Jason.decode!())
             ]
    end

    test "get_app_script!/1 returns the app_script with given id, with string keys instead of atoms" do
      app_script = app_script_fixture()
      %{script: script_content} = app_script

      assert APPScripts.get_app_script!(app_script.id) ==
               app_script
               |> Map.put(:script, script_content |> Jason.encode!() |> Jason.decode!())
    end

    test "create_app_script/1 with valid data creates a app_script" do
      %{script: script_content} = app_script_fixture()
      valid_attrs = %{name: "some name", script: script_content}

      assert {:ok, %APP{} = app_script} = APPScripts.create_app_script(valid_attrs)
      assert app_script.name == "some name"
      assert app_script.script == script_content
    end

    test "create_app_script/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = APPScripts.create_app_script(@invalid_attrs)
    end

    test "update_app_script/2 with valid data updates the app_script" do
      app_script = app_script_fixture()
      %{script: script_content} = app_script
      update_attrs = %{name: "some updated name", script: script_content}

      assert {:ok, %APP{} = app_script} = APPScripts.update_app_script(app_script, update_attrs)
      assert app_script.name == "some updated name"
      assert app_script.script == script_content
    end

    test "update_app_script/2 with invalid data returns error changeset" do
      app_script = app_script_fixture()
      %{script: script_content} = app_script

      stored_app_script =
        app_script |> Map.put(:script, script_content |> Jason.encode!() |> Jason.decode!())

      assert {:error, %Ecto.Changeset{}} =
               APPScripts.update_app_script(app_script, @invalid_attrs)

      assert stored_app_script ==
               APPScripts.get_app_script!(app_script.id)
    end

    test "delete_app_script/1 deletes the app_script" do
      app_script = app_script_fixture()
      assert {:ok, %APP{}} = APPScripts.delete_app_script(app_script)
      assert_raise Ecto.NoResultsError, fn -> APPScripts.get_app_script!(app_script.id) end
    end

    test "change_app_script/1 returns a app_script changeset" do
      app_script = app_script_fixture()
      assert %Ecto.Changeset{} = APPScripts.change_app_script(app_script)
    end
  end
end

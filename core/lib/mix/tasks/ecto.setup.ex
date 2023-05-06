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

defmodule Mix.Tasks.Ecto.Setup do
  @moduledoc """
  Performs all database setup operations, both for the main database and the subjects database.

  This task is a shortcut for running the following tasks:

  - mix ecto.create
  - mix ecto.create -r Core.SubjectsRepo
  - mix ecto.migrate
  - mix ecto.migrate -r Core.SubjectsRepo
  """
  @shortdoc "Setup for core and subjects databases"

  @requirements ["app.config"]

  @preferred_cli_env :dev

  use Mix.Task

  @impl Mix.Task
  def run(_args) do
    Mix.shell().info("Creating databases...")
    Mix.Task.run("ecto.create", [])
    Mix.Task.rerun("ecto.create", ["-r", "Core.SubjectsRepo"])
    Mix.shell().info("Performing migrations...")
    Mix.Task.run("ecto.migrate", [])
    Mix.Task.rerun("ecto.migrate", ["-r", "Core.SubjectsRepo"])
  end
end

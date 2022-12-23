# Copyright 2022 Giuseppe De Palma, Matteo Trentin
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

defmodule Core.Release do
  @moduledoc """
  This module contains the functions to run migrations and seeds after release.
  """
  require Logger

  @app :core

  def migrate do
    Logger.info("***** RUNNING MIGRATIONS *****")
    load_app()

    for repo <- repos() do
      {:ok, _, _} = Ecto.Migrator.with_repo(repo, &Ecto.Migrator.run(&1, :up, all: true))
    end

    Logger.info("***** MIGRATIONS COMPLETED *****")
  end

  @spec seed(Ecto.Repo.t(), String.t()) :: :ok | {:error, any()}
  def seed(repo, filename) do
    Logger.info("***** SEEDING DATABASE *****")
    load_app()

    case Ecto.Migrator.with_repo(repo, &eval_seed(&1, filename)) do
      {:ok, {:ok, _fun_return}, _apps} ->
        Logger.info("***** DATABASE SEEDED *****")
        :ok

      {:ok, {:error, reason}, _apps} ->
        Logger.error(reason)
        {:error, reason}

      {:error, term} ->
        Logger.warning(term)
        {:error, term}
    end
  end

  @spec eval_seed(Ecto.Repo.t(), String.t()) :: any()
  defp eval_seed(repo, filename) do
    seeds_file = get_path(repo, "seeds", filename)

    if File.regular?(seeds_file) do
      {:ok, Code.eval_file(seeds_file)}
    else
      {:error, "Seeds file not found."}
    end
  end

  @spec get_path(Ecto.Repo.t(), String.t(), String.t()) :: String.t()
  defp get_path(repo, directory, filename) do
    priv_dir = "#{:code.priv_dir(@app)}"

    repo_underscore =
      repo
      |> Module.split()
      |> List.last()
      |> Macro.underscore()

    Path.join([priv_dir, repo_underscore, directory, filename])
  end

  def rollback(repo, version) do
    load_app()
    {:ok, _, _} = Ecto.Migrator.with_repo(repo, &Ecto.Migrator.run(&1, :down, to: version))
  end

  defp repos do
    Application.fetch_env!(@app, :ecto_repos)
  end

  defp load_app do
    Application.load(@app)
  end
end

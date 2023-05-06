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

defmodule Core.Adapters.Subjects.Cache do
  @moduledoc """
  A GenServer that implements a cache for subjects and tokens.

  The cache is implemented as an ETS table, accessed through a GenServer.
  """
  @behaviour Core.Domain.Ports.SubjectCache

  use GenServer, restart: :permanent
  require Logger

  @subjects_cache_server :subjects_cache_server
  @subjects_cache_table :subjects_cache

  @doc """
  Retrieve a token from the cache, associated to a subject.

  ## Parameters
  - `subject`: the subject name string

  ## Returns
  - `token` if the token is found;
  - `:subject_not_found` if the token is not found.
  """
  @impl true
  def get(subject) do
    case :ets.lookup(@subjects_cache_table, subject) do
      [{^subject, token}] -> token
      _ -> :subject_not_found
    end
  end

  @doc """
  Store a token in the cache, associated to a subject.

  ## Parameters
  - `subject`: the subject name string
  - `token`: the token to store

  ## Returns
  - `:ok`
  """
  @impl true
  def insert(subject, token) do
    GenServer.call(@subjects_cache_server, {:insert, subject, token})
  end

  @doc """
  Delete a token from the cache, associated to a subject.

  ## Parameters
  - `subject`: the subject name string

  ## Returns
  - `:ok`
  """
  @impl true
  def delete(subject) do
    GenServer.call(@subjects_cache_server, {:delete, subject})
  end

  # GenServer callbacks
  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: @subjects_cache_server)
  end

  @impl true
  def init(_args) do
    table = :ets.new(@subjects_cache_table, [:set, :named_table, :protected])
    {:ok, table}
  end

  @impl true
  def handle_call({:insert, name, token}, _from, table) do
    :ets.insert(table, {name, token})
    Logger.info("Subjects Cache: added subject #{name}.")
    {:reply, :ok, table}
  end

  @impl true
  def handle_call({:delete, name}, _from, table) do
    :ets.delete(table, name)
    Logger.info("Subject Cache: removes subject #{name}.")
    {:reply, :ok, table}
  end
end

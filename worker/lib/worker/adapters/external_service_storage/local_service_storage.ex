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

defmodule Worker.Adapters.ExternalServiceStorage.LocalServiceStorage do
  @moduledoc """
  Local storage adapter for services information (name and endpoint).
  Uses Cachex to store this information both in-memory and on disk.
  """
  require Logger
  @behaviour Worker.Domain.Ports.ExternalServiceStorage

  @cache :service_info_cache

  @impl true
  def get(key) do
    {:ok, value} = Cachex.get(@cache, key)

    case value do
      nil -> {:error, :not_found}
      _ -> {:ok, value}
    end
  end

  @impl true
  def insert(key, value) do
    Logger.info("Inserting service info: #{key} -> #{value}")

    {:ok, v} = Cachex.get(@cache, key)

    case v do
      nil ->
        Cachex.put(@cache, key, value)
        Logger.info("Service info inserted")
        :ok

      _ ->
        Logger.error("Service info already exists")
        {:error, :exists}
    end
  end

  @impl true
  def update(key, value) do
    {:ok, v} = Cachex.get(@cache, key)

    case v do
      nil ->
        {:error, :not_found}

      _ ->
        Cachex.put(@cache, key, value)
        Logger.info("Updated latency (#{value} ms) for service: '#{key}'")
        :ok
    end
  end

  @impl true
  def keys() do
    Cachex.keys(@cache)
  end

  @impl true
  def upsert(key, value) do
    case Cachex.put(@cache, key, value) do
      {:ok, _} -> :ok
      {:error, _} -> :error
    end
  end

  @impl true
  def delete(key) do
    {:ok, v} = Cachex.get(@cache, key)

    case v do
      nil ->
        {:error, :not_found}

      _ ->
        Cachex.del(@cache, key)
        :ok
    end
  end
end

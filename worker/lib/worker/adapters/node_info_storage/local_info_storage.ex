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

defmodule Worker.Adapters.NodeInfoStorage.LocalInfoStorage do
  @behaviour Worker.Domain.Ports.NodeInfoStorage

  # TODO: use Cachex to store node info (disk+memory)
  @cache :node_info_cache
  @info_path :worker |> Application.compile_env!(__MODULE__) |> Keyword.fetch!(:path)

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
    {:ok, v} = Cachex.get(@cache, key)

    case v do
      nil ->
        Cachex.put(@cache, key, value)
        Cachex.dump(@cache, @info_path)
        :ok

      _ ->
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
        Cachex.dump(@cache, @info_path)
        :ok
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
        Cachex.dump(@cache, @info_path)
        :ok
    end
  end
end

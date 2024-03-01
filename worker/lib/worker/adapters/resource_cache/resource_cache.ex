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

defmodule Worker.Adapters.ResourceCache do
  @moduledoc """
    Implements the ResourceCache behaviour.
    It uses a GenServer process having exclusive writing rights on an underlying ETS table.

    The {function_name, module} couples are the keys that point to ExecutionResources.
  """
  @behaviour Worker.Domain.Ports.ResourceCache
  @cache :resource_cache

  @doc """
  Retrieve a resource from the cache, associated with a function name and a module.
  Checks if the retrieved resource matches the given hash; if it doesn't, it's ignored.

  ## Parameters
  - `function_name`: the name of the function
  - `module`: the module of the function
  - `hash`: the hash of the non-compiled code of the function.

  ## Returns
  - `resource` if the resource is found;
  - `:resource_not_found` if the resource is not found.
  """
  @impl true
  def get(function_name, module, hash) do
    case Cachex.get(@cache, {function_name, module, hash}) do
      {:ok, resource} when resource != nil ->
        Cachex.touch(@cache, {function_name, module, hash})
        Cachex.refresh(@cache, {function_name, module, hash})
        resource

      _ ->
        :resource_not_found
    end
  end

  @doc """
  Store a resource in the cache, associated with a function name and a module.

  ## Parameters
  - `function_name`: the name of the function
  - `module`: the module of the function
  - `resource`: the resource to store

  ## Returns
  - `:ok`
  """
  @impl true
  def insert(function_name, module, hash, resource) do
    {entry_ttl, _} =
      :worker
      |> Application.fetch_env!(__MODULE__)
      |> Keyword.fetch!(:cachex_ttl)
      |> Integer.parse()

    Cachex.transaction(@cache, [{function_name, module, hash}], fn worker ->
      key = {function_name, module, hash}

      if Cachex.get(worker, key) == {:ok, nil} do
        Cachex.put(@cache, key, resource, ttl: :timer.minutes(entry_ttl))
      end
    end)

    :ok
  end

  @doc """
  Remove a resource from the cache, associated with a function name and a module.

  ## Parameters
  - `function_name`: the name of the function
  - `module`: the module of the function

  ## Returns
  - `:ok`
  """
  @impl true
  def delete(function_name, module, hash) do
    Cachex.transaction(@cache, [{function_name, module, hash}], fn worker ->
      key = {function_name, module, hash}

      case Cachex.get(worker, key) do
        {:ok, r} when r != nil -> Cachex.del(@cache, key)
        _ -> :ok
      end
    end)

    :ok
  end
end

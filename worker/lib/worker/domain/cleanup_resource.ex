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

defmodule Worker.Domain.CleanupResource do
  @moduledoc """
  Contains functions used to remove function runtimes. Side effects (e.g. docker interaction) are delegated to ports and adapters.
  """
  alias Worker.Adapters.RawResourceStorage
  alias Data.FunctionStruct
  alias Worker.Domain.Ports.ResourceCache
  alias Worker.Domain.Ports.Runtime.Cleaner

  require Elixir.Logger

  @doc """
    Removes the resource associated with the given function. It is removed from the ResourceCache and
    the adapter Cleaner is executed.

    ## Parameters
      - function: the FunctionStruct containing the function information (name, module and hash)

    ## Returns
      - :ok if the resource is found and removed successfully;
      - {:error, err} if the same error is encountered while removing the resource from
        ResourceCache and RawResourceStorage;
      - {:error, {{:cache, res1}, {:raw_storage, res2}}} if ResourceCache and RawResourceStorage returned
        two different values on cleanup.
  """
  @spec cleanup(FunctionStruct.t()) ::
          :ok | {:error, {{:cache, any()}, {:raw_storage, any()}}} | {:error, any()}
  def cleanup(%{__struct__: _s} = function), do: cleanup(Map.from_struct(function))

  def cleanup(%{name: _fname, module: _mod, hash: _hash} = function) do
    cleanup_cache_result = cleanup_cache(function)
    cleanup_raw_result = cleanup_raw(function)
    cleanup_return(cleanup_cache_result, cleanup_raw_result)
  end

  defp cleanup_cache(%{name: fname, module: mod, hash: hash} = _function) do
    with resource when resource != :resource_not_found <- ResourceCache.get(fname, mod, hash),
         :ok <- Cleaner.cleanup(resource),
         :ok <- ResourceCache.delete(fname, mod, hash) do
      Logger.info("API: Resource for function #{fname} in module #{mod} deleted")
      :ok
    else
      :resource_not_found -> {:error, :resource_not_found}
      err -> err
    end
  end

  defp cleanup_raw(%{name: fname, module: mod, hash: hash} = _function) do
    case RawResourceStorage.delete(fname, mod, hash) do
      :ok ->
        Logger.info("API: Raw resource for function #{fname} in module #{mod} deleted")
        :ok

      {:error, :enoent} ->
        {:error, :resource_not_found}

      err ->
        err
    end
  end

  defp cleanup_return(:ok, :ok) do
    :ok
  end

  defp cleanup_return({:error, err}, {:error, err}) do
    {:error, err}
  end

  defp cleanup_return(cache_result, raw_result) do
    {:error, {{:cache, cache_result}, {:raw_storage, raw_result}}}
  end
end

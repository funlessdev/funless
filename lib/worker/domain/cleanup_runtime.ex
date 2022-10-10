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

defmodule Worker.Domain.CleanupRuntime do
  @moduledoc """
  Contains functions used to remove function runtimes. Side effects (e.g. docker interaction) are delegated to ports and adapters.
  """
  alias Worker.Domain.Ports.Runtime.Cleaner

  import Worker.Domain.Ports.RuntimeCache, only: [get: 2, delete: 2]

  require Elixir.Logger

  @doc """
    Removes the first runtime associated with the given function.

    ## Parameters
      - %{...}: generic struct with all the fields required by Worker.Domain.Function

    ## Returns
      - :ok if a runtime is found and removed successfully;
      - {:error, err} if a runtime is found, but an error is encountered when removing it.
  """
  @spec cleanup(map()) :: :ok | {:error, any}
  def cleanup(%{__struct__: _s} = function), do: cleanup(Map.from_struct(function))

  def cleanup(%{name: fname, namespace: ns} = _function) do
    get(fname, ns)
    |> run_cleaner
    |> remove_runtime_from_cache(fname, ns)
  end

  def cleanup(_), do: {:error, :bad_params}

  defp run_cleaner(:runtime_not_found) do
    Logger.warn("API: Error cleaning up runtime: no runtime found to cleanup")
    {:error, :runtime_not_found}
  end

  defp run_cleaner(runtime) do
    Logger.info("API: Cleaning up runtime: #{runtime.name}")
    Cleaner.cleanup(runtime)
  end

  defp remove_runtime_from_cache({:ok, _}, fname, ns) do
    Logger.info("API: Runtime of #{fname} successfully cleaned up")
    delete(fname, ns)
  end

  defp remove_runtime_from_cache(err, _, _), do: err
end

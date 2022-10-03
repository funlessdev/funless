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
  alias Worker.Domain.FunctionStruct
  alias Worker.Domain.Ports.Runtime.Cleaner

  import Worker.Domain.Ports.RuntimeTracker, only: [get_runtimes: 1, delete_runtime: 2]

  require Elixir.Logger

  @doc """
    Removes the first runtime associated with the given function.

    Returns {:ok, runtime_name} if the cleanup is successful;
    returns {:error, err} if any error is encountered (both while removing the runtime and when searching for it).

    ## Parameters
      - %{...}: generic struct with all the fields required by Worker.Domain.Function
  """
  @spec cleanup(map()) :: {:ok, String.t()} | {:error, any}
  def cleanup(%{__struct__: _s} = function), do: cleanup(Map.from_struct(function))

  def cleanup(%{name: fname, namespace: _namespace} = _function) do
    fname
    |> get_runtimes
    |> run_cleaner
    |> remove_runtime_from_store(fname)
  end

  def cleanup(_), do: {:error, :bad_params}

  @doc """
    Removes all the runtimes associated with the given function.

    Returns {:ok, runtime_list} if the cleanup is successful;
    returns {:error, err} if any error is encountered (both while removing the runtime and when searching for it).

    ## Parameters
      - function: a struct with all the fields required by Worker.Domain.Function
  """
  @spec cleanup_all(FunctionStruct.t()) ::
          {:ok, list()} | {:error, String.t()} | {:error, [{String.t(), any}]}

  def cleanup_all(%{__struct__: _s} = function), do: cleanup_all(Map.from_struct(function))

  def cleanup_all(%{name: fname, namespace: _namespace} = function) do
    r_list =
      fname
      |> get_runtimes()
      |> run_cleaner_all
      |> remove_all_runtimes_from_store(function)

    case r_list do
      [] -> {:ok, []}
      [_ | _] -> {:error, r_list}
      {:error, err} -> {:error, err}
    end
  end

  def cleanup_all(_), do: {:error, :bad_params}

  # Private functions
  defp run_cleaner([]) do
    Logger.error("API: Error cleaning up runtime: no runtime found to cleanup")
    {:error, "no runtime found to cleanup"}
  end

  defp run_cleaner([runtime | _]) do
    Logger.info("API: Cleaning up runtime: #{runtime.name}")
    Cleaner.cleanup(runtime)
  end

  defp run_cleaner_all([]) do
    Logger.error("API: Error cleaning up runtime: no runtime found to cleanup")
    {:error, "no runtimes found to cleanup"}
  end

  defp run_cleaner_all([_runtime | _] = runtimes) do
    Logger.info("API: Cleaning up runtimes...")
    Enum.map(runtimes, &Cleaner.cleanup(&1))
  end

  defp remove_all_runtimes_from_store({:error, err}, _) do
    {:error, err}
  end

  defp remove_all_runtimes_from_store([_h | _] = result_list, function) do
    result_list
    |> Enum.map(&remove_runtime_from_store(&1, function.name))
    |> Enum.filter(fn rt ->
      case rt do
        {:error, _} -> true
        _ -> false
      end
    end)
  end

  defp remove_runtime_from_store({:ok, runtime}, function_name) do
    case delete_runtime(function_name, runtime) do
      {:ok, _} -> {:ok, runtime}
      {:error, err} -> {:error, err}
    end
  end

  defp remove_runtime_from_store(err, _), do: err
end

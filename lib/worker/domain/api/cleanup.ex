# Licensed to the Apache Software Foundation (ASF) under one
# or more contributor license agreements.  See the NOTICE file
# distributed with this work for additional information
# regarding copyright ownership.  The ASF licenses this file
# to you under the Apache License, Version 2.0 (the
# "License"); you may not use this file except in compliance
# with the License.  You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing,
# software distributed under the License is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
# KIND, either express or implied.  See the License for the
# specific language governing permissions and limitations
# under the License.
#
defmodule Worker.Domain.Api.Cleanup do
  @moduledoc """
  Contains functions used to remove function runtimes. Side effects (e.g. docker interaction) are delegated to ports and adapters.
  """

  alias Worker.Domain.Ports.Runtime
  alias Worker.Domain.Ports.RuntimeTracker

  alias Worker.Domain.FunctionStruct

  require Elixir.Logger

  @doc """
    Removes the first runtime associated with the given function.

    Returns {:ok, runtime_name} if the cleanup is successful;
    returns {:error, err} if any error is encountered (both while removing the runtime and when searching for it).

    ## Parameters
      - %{...}: generic struct with all the fields required by Worker.Domain.Function
  """
  @spec cleanup(Map.t()) :: {:ok, String.t()} | {:error, any}
  def cleanup(%{__struct__: _s} = f), do: cleanup(Map.from_struct(f))

  def cleanup(%{name: _fname, image: _image, namespace: _namespace, code: _code} = f) do
    function = struct(FunctionStruct, f)

    RuntimeTracker.get_runtimes(function.name)
    |> runtime_cleanup
    |> remove_runtime_from_store(function.name)
  end

  def cleanup(_), do: {:error, :bad_params}

  defp runtime_cleanup([]) do
    Logger.error("API: Error cleaning up runtime: no runtime found to cleanup")
    {:error, "no runtime found to cleanup"}
  end

  defp runtime_cleanup([runtime | _]) do
    Logger.info("API: Cleaning up runtime: #{runtime.name}")
    Runtime.cleanup(runtime)
  end

  @doc """
    Removes the all runtimes associated with the given function.

    Returns {:ok, runtime_name} if the cleanup is successful;
    returns {:error, err} if any error is encountered (both while removing the runtime and when searching for it).

    ## Parameters
      - %{...}: generic struct with all the fields required by Worker.Domain.Function
  """
  @spec cleanup_all(Map.t()) ::
          {:ok, List.t()} | {:error, String.t()} | {:error, [{String.t(), any}]}

  def cleanup_all(%{__struct__: _s} = f), do: cleanup_all(Map.from_struct(f))

  def cleanup_all(%{name: _fname, image: _image, namespace: _namespace, code: _code} = f) do
    function = struct(FunctionStruct, f)

    r_list =
      RuntimeTracker.get_runtimes(function.name)
      |> runtime_cleanup_all
      |> remove_all_runtime_from_store(function)

    case r_list do
      [] ->
        {:ok, []}

      [_ | _] ->
        {:error, r_list |> Enum.map(fn {:error, runtime_name, err} -> {runtime_name, err} end)}

      {:error, err} ->
        {:error, err}
    end
  end

  def cleanup_all(_), do: {:error, :bad_params}

  defp runtime_cleanup_all([]) do
    Logger.error("API: Error cleaning up runtime: no runtime found to cleanup")
    {:error, "no runtime found to cleanup"}
  end

  defp runtime_cleanup_all([_runtime | _] = runtimes) do
    Logger.info("API: Cleaning up runtimes: #{runtimes}")

    runtimes
    |> Enum.map(fn runtime ->
      res = Runtime.cleanup(runtime)

      case res do
        {:ok, runtime_name} -> {:ok, runtime_name}
        {:error, err} -> {:error, runtime.name, err}
      end
    end)
  end

  defp remove_all_runtime_from_store({:error, err}, _) do
    {:error, err}
  end

  defp remove_all_runtime_from_store([_h | _] = result_list, function) do
    result_list
    |> Enum.map(fn r ->
      remove_runtime_from_store(r, function.name)
    end)
    |> Enum.filter(fn r ->
      case r do
        {:error, _, _} -> true
        _ -> false
      end
    end)
  end

  defp remove_runtime_from_store({:ok, runtime}, function_name) do
    RuntimeTracker.delete_runtime(function_name, runtime)
    {:ok, runtime}
  end

  defp remove_runtime_from_store(err, _), do: err
end

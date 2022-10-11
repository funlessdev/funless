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

defmodule Worker.Domain.ProvisionRuntime do
  @moduledoc """
  Contains functions used to create function runtimes. Side effects (e.g. docker interaction) are delegated to ports and adapters.
  """

  alias Worker.Domain.Ports.Runtime.Provisioner
  alias Worker.Domain.Ports.RuntimeCache

  alias Worker.Domain.CleanupRuntime
  alias Worker.Domain.RuntimeStruct

  require Elixir.Logger

  @doc """
  Provisions a runtime for the given function.

  It uses the Provisioner adapter to get the runtime from the cache or, depending on the
  adapter, it creates one and returns it after inserting it in the cache.


  ## Parameters
  - %{...}: generic struct with all the fields required by Worker.Domain.Function

  ## Returns
  - `{:ok, runtime}` if the runtime is found or created.
  - `{:error, :runtime_not_found} if the runtime was not in the cache and it won't attempt to create one.
  - `{:error, err}` if any error is encountered
  """
  @spec provision(map()) :: {:ok, RuntimeStruct.t()} | {:error, any}

  def provision(%{name: fname, namespace: ns} = f) do
    Provisioner.provision(f) |> store_prepared_runtime(fname, ns)
  end

  def provision(_), do: {:error, :bad_params}

  @dialyzer {:nowarn_function, [store_prepared_runtime: 3]}
  @spec store_prepared_runtime({atom(), any}, String.t(), String.t()) ::
          {:ok, RuntimeStruct.t()} | {:error, any}
  defp store_prepared_runtime({:ok, runtime}, function_name, namespace) do
    case RuntimeCache.insert(function_name, namespace, runtime) do
      :ok ->
        Logger.info("API: Runtime #{runtime.name} ready and tracked")
        {:ok, runtime}

      {:error, err} ->
        Logger.error("API: Failed to store runtime #{runtime.name} in cache after creation")
        CleanupRuntime.cleanup(runtime)
        {:error, err}
    end
  end

  defp store_prepared_runtime({:error, err}, _, _) do
    Logger.error("API: Runtime preparation failed: #{inspect(err)}")
    {:error, err}
  end
end

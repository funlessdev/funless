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

defmodule Worker.Domain.ProvisionResource do
  @moduledoc """
  Contains functions used to create function runtimes. Side effects (e.g. docker interaction) are delegated to ports and adapters.
  """

  alias Data.ExecutionResource
  alias Data.FunctionStruct
  alias Worker.Domain.Ports.ResourceCache
  alias Worker.Domain.Ports.Runtime.Cleaner
  alias Worker.Domain.Ports.Runtime.Provisioner

  require Elixir.Logger

  @doc """
  Provisions an execution resource for the given function.

  It uses the Provisioner adapter to get the runtime from the cache or, depending on the
  adapter, it creates one and returns it after inserting it in the cache.

  ## Parameters
  - %{...}: generic struct with all the fields required by Data.Function

  ## Returns
  - `{:ok, resource}` if the resource is found or created.
  - `{:error, :resource_not_found} if the resource was not in the cache and it won't attempt to create one.
  - `{:error, err}` if any error is encountered
  """
  @spec provision(FunctionStruct.t()) :: {:ok, ExecutionResource.t()} | {:error, any}
  def provision(%{name: name, module: ns} = f) do
    Logger.info("API: Provisioning runtime for #{name} in module #{ns}")

    case ResourceCache.get(name, ns) do
      :resource_not_found ->
        Logger.warn("Resource not found in cache")
        Provisioner.provision(f) |> cache_resource(name, ns)

      resource ->
        Logger.info("Resource found in cache")
        {:ok, resource}
    end
  end

  def provision(_), do: {:error, :bad_params}

  @dialyzer {:nowarn_function, [cache_resource: 3]}
  @spec cache_resource({:ok, ExecutionResource.t()} | {:error, any()}, String.t(), String.t()) ::
          {:ok, ExecutionResource.t()} | {:error, any}
  defp cache_resource({:error, err}, _, _), do: {:error, err}

  defp cache_resource({:ok, resource}, fname, ns) do
    case ResourceCache.insert(fname, ns, resource) do
      :ok ->
        Logger.info("API: Resource for {#{fname}, #{ns}} added to cache")
        {:ok, resource}

      err ->
        Logger.error("API: Failed to cache resource")
        Cleaner.cleanup(resource)
        err
    end
  end
end

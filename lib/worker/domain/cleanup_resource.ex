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

defmodule Worker.Domain.CleanupResource do
  @moduledoc """
  Contains functions used to remove function runtimes. Side effects (e.g. docker interaction) are delegated to ports and adapters.
  """
  alias Worker.Domain.FunctionStruct
  alias Worker.Domain.Ports.ResourceCache
  alias Worker.Domain.Ports.Runtime.Cleaner

  require Elixir.Logger

  @doc """
    Removes the resource associated with the given function. It is removed from the ResourceCache and
    the adapter Cleaner is executed.

    ## Parameters
      - function: the FunctionStruct containing the function information (name and namespace)

    ## Returns
      - :ok if the resource is found and removed successfully;
      - {:error, err} if an error is encountered while removing the resource.
  """
  @spec cleanup(FunctionStruct.t()) :: :ok | {:error, any}
  def cleanup(%{__struct__: _s} = function), do: cleanup(Map.from_struct(function))

  def cleanup(%{name: fname, namespace: ns} = _function) do
    with resource when resource != :resource_not_found <- ResourceCache.get(fname, ns),
         :ok <- Cleaner.cleanup(resource),
         :ok <- ResourceCache.delete(fname, ns) do
      Logger.info("Resource for function #{fname} in namespace #{ns} deleted")
      :ok
    else
      :resource_not_found -> {:error, :resource_not_found}
      err -> err
    end
  end
end

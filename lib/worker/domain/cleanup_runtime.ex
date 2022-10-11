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
  alias Worker.Domain.Ports.RuntimeCache

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
    with runtime when runtime != :runtime_not_found <- RuntimeCache.get(fname, ns),
         :ok <- Cleaner.cleanup(runtime),
         :ok <- RuntimeCache.delete(fname, ns) do
      Logger.info("API: Runtime for function #{fname} in namespace #{ns} deleted")
      :ok
    else
      :runtime_not_found -> {:error, :runtime_not_found}
      err -> err
    end
  end
end

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

defmodule Worker.Domain.InvokeFunction do
  @moduledoc """
  Contains functions used to run function runtimes. Side effects (e.g. docker interaction) are delegated to ports and adapters.
  """

  alias Worker.Domain.Ports.Runtime.Runner
  alias Worker.Domain.ProvisionResource

  alias Worker.Domain.FunctionStruct

  require Elixir.Logger

  @doc """
    Invokes the given function if an associated runtime exists, using the RuntimeCache and Runtime callbacks.

    ## Parameters
      - the list of available runtimes to use
      - %{...}: struct with all the fields required by Worker.Domain.Function
      - args: arguments passed to the function

    ## Returns
      - {:ok, result} if a runtime exists and the function runs successfully;
      - {:error, {:noruntime, err}} if no runtime is found;
      - {:error, err} if a runtime is found, but an error is encountered when running the function.
  """
  @spec invoke(map(), map()) :: {:ok, any} | {:error, any}
  def invoke(_, args \\ %{})

  def invoke(%{__struct__: _s} = f, args), do: invoke(Map.from_struct(f), args)

  def invoke(%{name: _fname, namespace: _namespace} = function, args) do
    f = struct(FunctionStruct, function)
    Logger.info("API: Invoking function #{f.name} in namespace #{f.namespace}")

    with {:ok, runtime} <- ProvisionResource.provision(f) do
      Runner.run_function(function, args, runtime)
    end
  end

  def invoke(_, _), do: {:error, :bad_params}
end

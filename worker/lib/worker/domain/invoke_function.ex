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

defmodule Worker.Domain.InvokeFunction do
  @moduledoc """
  Contains functions used to run function runtimes. Side effects (e.g. docker interaction) are delegated to ports and adapters.
  """

  alias Worker.Domain.Ports.WaitForCode
  alias Worker.Domain.Ports.Runtime.Runner
  alias Worker.Domain.ProvisionResource

  alias Data.FunctionStruct

  require Elixir.Logger

  @doc """
    Invokes the given function if an associated execution resource exists, using the ResourceCache and Runtime callbacks.

    ## Parameters
      - %{...}: struct with all the fields required by Data.FunctionStruct
      - args: arguments passed to the function

    ## Returns
      - {:ok, result} if a resource exists and the function runs successfully;
      - {:error, :code_not_found} if no resource is found and it cannot create one;
      - {:error, err} if a resource is found, but an error is encountered when running the function.
  """
  @spec invoke(map(), map()) :: {:ok, any} | {:error, :code_not_found} | {:error, any}
  def invoke(_, args \\ %{})

  def invoke(%{__struct__: _s} = f, args), do: invoke(Map.from_struct(f), args)

  def invoke(%{name: name, module: mod} = function, args) do
    f = struct(FunctionStruct, function)
    Logger.info("API: Invoking function #{mod}/#{name}")

    case ProvisionResource.provision(f) do
      {:ok, resource} ->
        Runner.run_function(function, args, resource)

      {:error, :code_not_found} ->
        {:ok, pid} = WaitForCode.wait_for_code(args)
        {:error, :code_not_found, pid}

      {:error, err} ->
        {:error, err}
    end
  end

  def invoke(_, _), do: {:error, :bad_params}
end

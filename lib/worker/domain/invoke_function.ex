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
defmodule Worker.Domain.InvokeFunction do
  @moduledoc """
  Contains functions used to run function runtimes. Side effects (e.g. docker interaction) are delegated to ports and adapters.
  """

  alias Worker.Domain.Ports.Runtime.Runner
  alias Worker.Domain.ProvisionRuntime
  import Worker.Domain.Ports.RuntimeTracker, only: [get_runtimes: 1]

  alias Worker.Domain.FunctionStruct
  alias Worker.Domain.RuntimeStruct

  require Elixir.Logger

  @doc """
    Invokes the given function if an associated runtime exists, using the RuntimeTracker and Runtime callbacks.

    Returns {:ok, result} if a runtime exists and the function runs successfully;
    returns {:error, {:noruntime, err}} if no runtime is found;
    returns {:error, err} if a runtime is found, but an error is encountered when running the function.


    ## Parameters
      - the list of available runtimes to use
      - %{...}: struct with all the fields required by Worker.Domain.Function
      - args: arguments passed to the function
  """
  @spec invoke(map(), map()) :: {:ok, any} | {:error, any}
  def invoke(_, args \\ %{})

  def invoke(%{__struct__: _s} = f, args), do: invoke(Map.from_struct(f), args)

  def invoke(
        %{name: _fname, image: _image, namespace: _namespace, code: _code} = function,
        args
      ) do
    f = struct(FunctionStruct, function)
    Logger.info("API: Invoking function #{f.name}")

    f.name
    |> get_runtimes
    |> run_function(f, args)
  end

  def invoke(_, _), do: {:error, :bad_params}

  @spec run_function([RuntimeStruct.t()], FunctionStruct.t(), map()) ::
          {:ok, any} | {:error, any}
  defp run_function([runtime | _], %FunctionStruct{} = function, args) do
    Logger.info("API: Found runtime: #{runtime.name} for function #{function.name}")
    Runner.run_function(function, args, runtime)
  end

  @dialyzer {:nowarn_function, run_function: 3}
  defp run_function([], %FunctionStruct{} = function, args) do
    Logger.warn("API: no runtime found to run function #{function.name}, creating one...")

    case ProvisionRuntime.prepare_runtime(function) do
      {:ok, runtime} -> run_function([runtime], function, args)
      {:error, err} -> {:error, err}
    end
  end
end

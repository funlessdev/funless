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
defmodule Worker.Domain.Api.Invoke do
  @moduledoc """
  Contains functions used to run function runtimes. Side effects (e.g. docker interaction) are delegated to ports and adapters.
  """

  alias Worker.Domain.Api.Prepare

  alias Worker.Domain.Ports.Runtime
  alias Worker.Domain.Ports.RuntimeTracker

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
  @spec invoke_function(Map.t(), Map.t()) :: {:ok, any} | {:error, any}
  def invoke_function(_, args \\ %{})

  def invoke_function(%{__struct__: _s} = f, args),
    do: invoke_function(Map.from_struct(f), args)

  def invoke_function(
        %{name: _fname, image: _image, namespace: _namespace, code: _code} = f,
        args
      ) do
    function = struct(FunctionStruct, f)
    Logger.info("API: Invoking function #{function.name}")
    RuntimeTracker.get_runtimes(function.name) |> run_function(function, args)
  end

  def invoke_function(_, _), do: {:error, :bad_params}

  @spec run_function([RuntimeStruct], FunctionStruct.t(), map()) ::
          {:ok, any} | {:error, any}
  defp run_function(
         [runtime | _],
         %FunctionStruct{} = function,
         args
       ) do
    Logger.info("API: Found runtime: #{runtime.name} for function #{function.name}")
    Runtime.run_function(function, args, runtime)
  end

  defp run_function(
         [],
         %FunctionStruct{} = function,
         args
       ) do
    Logger.warn("API: no runtime found to run function #{function.name}, creating one...")

    case Prepare.prepare_runtime(function) do
      {:ok, runtime} -> Runtime.run_function(function, args, runtime)
      {:error, err} -> {:error, err}
    end
  end
end

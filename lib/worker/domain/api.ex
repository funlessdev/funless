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

defmodule Worker.Domain.Runtime do
  @moduledoc """
    Runtime struct, passed to adapters.

    ## Fields
      - name: runtime name
      - host: runtime IP address
      - port: runtime port
  """
  @type t :: %__MODULE__{
          name: String.t(),
          host: String.t(),
          port: String.t()
        }
  @enforce_keys [:name]
  defstruct [:name, :host, :port]
end

defmodule Worker.Domain.Function do
  @moduledoc """
    Function struct, passed to adapters.

    ## Fields
      - name: function name
      - image: base Docker image for the function's runtime
      - archive: path of the tarball containing the function's code, will be copied into runtime
      - main_file: path of the function's main file inside the runtime
  """
  @type t :: %__MODULE__{
          name: String.t(),
          image: String.t(),
          archive: String.t(),
          main_file: String.t()
        }
  @enforce_keys [:name, :image, :archive, :main_file]
  defstruct [:name, :image, :archive, :main_file]
end

defmodule Worker.Domain.Api do
  @moduledoc """
  Contains functions used to create, run and remove function runtimes. Side effects (e.g. docker interaction) are delegated to ports and adapters.
  """
  alias Worker.Domain.Ports.FunctionStorage
  alias Worker.Domain.Ports.Runtime

  require Elixir.Logger

  @doc """
    Creates a runtime for the given function; in case of successful creation, the {function, runtime} couple is inserted in the function storage.

    Returns {:ok, runtime} if the runtime is created, otherwise forwards {:error, err} from the Runtime implementation.

    ## Parameters
      - %{...}: generic struct with all the fields required by Worker.Domain.Function
  """
  @spec prepare_runtime(Worker.Domain.Function.t()) ::
          {:ok, Worker.Domain.Runtime.t()} | {:error, any}
  def prepare_runtime(function) do
    runtime_name = function.name <> "-funless"
    Runtime.prepare(function, runtime_name) |> store_prepared_runtime(function.name)
  end

  defp store_prepared_runtime({:ok, runtime}, function_name) do
    Logger.info("API: Runtime prepared #{runtime.name}")
    FunctionStorage.insert_runtime(function_name, runtime)
    {:ok, runtime}
  end

  defp store_prepared_runtime({:error, err}, _) do
    Logger.error("API: Runtime preparation failed: #{err}")
    {:error, err}
  end

  @doc """
    Invokes the given function if an associated runtime exists, using the FunctionStorage and Runtime callbacks.

    Returns {:ok, result} if a runtime exists and the function runs successfully;
    returns {:error, {:noruntime, err}} if no runtime is found;
    returns {:error, err} if a runtime is found, but an error is encountered when running the function.


    ## Parameters
      - the list of available runtimes to use
      - %{...}: struct with all the fields required by Worker.Domain.Function
      - args: arguments passed to the function
  """
  @spec invoke_function(Worker.Domain.Function.t(), map()) :: {:ok, any} | {:error, any}
  def invoke_function(function, args \\ %{}) do
    Logger.info("API: Invoking function #{function.name}")
    FunctionStorage.get_runtimes(function.name) |> run_function(function, args)
  end

  @spec run_function([Worker.Domain.Runtime], Worker.Domain.Function.t(), map()) ::
          {:ok, any} | {:error, any}
  defp run_function(runtimes, function, args)

  defp run_function([runtime | _], function, args) do
    Logger.info("API: Found runtime: #{runtime.name} for function #{function.name}")
    Runtime.run_function(function, args, runtime)
  end

  defp run_function([], function, args) do
    Logger.warn("API: no runtime found to run function #{function.name}, creating one...")

    case prepare_runtime(function) do
      {:ok, runtime} -> Runtime.run_function(function, args, runtime)
      {:error, err} -> {:error, err}
    end
  end

  @doc """
    Removes the first runtime associated with the given function.

    Returns {:ok, runtime_name} if the cleanup is successful;
    returns {:error, err} if any error is encountered (both while removing the runtime and when searching for it).

    ## Parameters
      - %{...}: generic struct with all the fields required by Worker.Domain.Function
  """
  @spec cleanup(Worker.Domain.Function.t()) :: {:ok, String.t()} | {:error, any}
  def cleanup(function) do
    FunctionStorage.get_runtimes(function.name)
    |> runtime_cleanup
    |> remove_runtime_from_store(function.name)
  end

  defp runtime_cleanup([]) do
    Logger.error("API: Error cleaning up runtime: no runtime found to cleanup")
    {:error, "no runtime found to cleanup"}
  end

  defp runtime_cleanup([runtime | _]) do
    Logger.info("API: Cleaning up runtime: #{runtime.name}")
    Runtime.cleanup(runtime)
  end

  defp remove_runtime_from_store({:ok, runtime}, function_name) do
    FunctionStorage.delete_runtime(function_name, runtime)
    {:ok, runtime.name}
  end

  defp remove_runtime_from_store(err, _), do: err
end

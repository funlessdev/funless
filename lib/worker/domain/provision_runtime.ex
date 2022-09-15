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
defmodule Worker.Domain.ProvisionRuntime do
  @moduledoc """
  Contains functions used to create function runtimes. Side effects (e.g. docker interaction) are delegated to ports and adapters.
  """

  alias Worker.Domain.Ports.Runtime.Provisioner
  alias Worker.Domain.Ports.RuntimeTracker

  alias Worker.Domain.FunctionStruct
  alias Worker.Domain.RuntimeStruct

  require Elixir.Logger

  @doc """
  Creates a runtime for the given function; in case of successful creation, the {function, runtime} couple is inserted in the function storage.

  Returns {:ok, runtime} if the runtime is created, otherwise forwards {:error, err} from the Runtime implementation.

  ## Parameters
  - %{...}: generic struct with all the fields required by Worker.Domain.Function
  """
  @spec prepare_runtime(map()) :: {:ok, RuntimeStruct.t()} | {:error, any}
  def prepare_runtime(%{__struct__: _s} = f), do: prepare_runtime(Map.from_struct(f))

  def prepare_runtime(%{name: fname, image: _image, namespace: _namespace, code: _code} = f) do
    # Conversion needed to pass it to the rustler prepare_runtime function, perhaps move the conversion in cluster.ex?
    function = struct(FunctionStruct, f)

    runtime_name = fname <> "-funless"

    Provisioner.prepare(function, runtime_name) |> store_prepared_runtime(fname)
  end

  def prepare_runtime(_), do: {:error, :bad_params}

  @spec store_prepared_runtime({atom(), any}, String.t()) ::
          {:ok, RuntimeStruct.t()} | {:error, any}
  defp store_prepared_runtime({:ok, runtime}, function_name) do
    case RuntimeTracker.insert_runtime(function_name, runtime) do
      {:ok, _} ->
        Logger.info("API: Runtime #{runtime.name} ready and tracked")
        {:ok, runtime}

      {:error, err} ->
        Logger.error("API: Failed to store runtime #{runtime.name} in Tracker after creation")
        # TODO cleanup runtime
        {:error, err}
    end
  end

  defp store_prepared_runtime({:error, err}, _) do
    Logger.error("API: Runtime preparation failed: #{inspect(err)}")
    {:error, err}
  end
end

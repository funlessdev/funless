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

defmodule Worker.Adapters.Runtime.Wasm.Provisioner do
  @moduledoc """
    Adapter for WebAssembly runtime creation. As the
  """
  @behaviour Worker.Domain.Ports.Runtime.Provisioner

  alias Data.ExecutionResource
  alias Data.FunctionStruct
  alias Worker.Adapters.Runtime.Wasm.Engine

  require Logger

  @doc """
  Compiles the given function code into a wasmtime module and returns an execution resource
  containing the wasmtime Store and Module.
  """
  @impl true
  @spec provision(FunctionStruct.t()) :: {:ok, ExecutionResource.t()} | {:error, any()}
  def provision(function) do
    Logger.info("Wasm Provisioner: compiling #{function.module}/#{function.name} wasm module")

    function
    |> compile_module()
    |> wrap_in_execution_resource()
  end

  @spec compile_module(FunctionStruct.t()) ::
          {:ok, {Wasmex.Store.t(), Wasmex.Module.t()}} | {:error, any()}
  defp compile_module(function) when is_nil(function.code) or not is_binary(function.code) do
    {:error, :code_not_found}
  end

  defp compile_module(function) do
    with {:ok, store} <- Wasmex.Store.new(nil, Engine.get_handle()),
         {:ok, module} <- Wasmex.Module.compile(store, function.code) do
      {:ok, {store, module}}
    else
      {:error, msg} = error ->
        Logger.error(
          "Wasm Provisioner: error compiling #{function.module}/#{function.name}: #{inspect(msg)}"
        )

        error
    end
  end

  @spec wrap_in_execution_resource({:ok, {Wasmex.Store.t(), Wasmex.Module.t()}} | {:error, any()}) ::
          {:ok, ExecutionResource.t()} | {:error, any()}
  defp wrap_in_execution_resource({:ok, store_mod}),
    do: {:ok, %ExecutionResource{resource: store_mod}}

  defp wrap_in_execution_resource(error), do: error
end

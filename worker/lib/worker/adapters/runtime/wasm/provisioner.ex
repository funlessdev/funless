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
    function
    |> compile_module()
    |> wrap_in_execution_resource()
  end

  @spec compile_module(FunctionStruct.t()) ::
          {:ok, binary()} | {:error, any()}
  defp compile_module(%{module: mod, name: name, code: nil}) do
    Logger.warning("Provisioner: wasm binary not provided for #{mod}/#{name}")
    {:error, :code_not_found}
  end

  defp compile_module(%{name: name, module: mod, code: code}) when not is_binary(code) do
    Logger.warning("Provisioner: #{mod}/#{name} wasm code provided is not a binary")
    {:error, "invalid wasm code, not a binary"}
  end

  defp compile_module(%{name: name, module: mod, code: code}) do
    Logger.info("Provisioner: compiling #{mod}/#{name} wasm")

    case Wasmex.Engine.precompile_module(Engine.get_handle(), code) do
      {:ok, module} ->
        {:ok, module}

      {:error, msg} = error ->
        Logger.error("Provisioner: error compiling #{mod}/#{name}: #{inspect(msg)}")
        error
    end
  end

  @spec wrap_in_execution_resource({:ok, binary()} | {:error, any()}) ::
          {:ok, ExecutionResource.t()} | {:error, any()}
  defp wrap_in_execution_resource({:ok, mod}),
    do: {:ok, %ExecutionResource{resource: mod}}

  defp wrap_in_execution_resource(error), do: error
end

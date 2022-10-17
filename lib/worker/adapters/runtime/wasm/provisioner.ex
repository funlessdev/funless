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

defmodule Worker.Adapters.Runtime.Wasm.Provisioner do
  @moduledoc """
    Adapter for WebAssembly runtime creation. As the
  """
  @behaviour Worker.Domain.Ports.Runtime.Provisioner

  alias Worker.Adapters.Runtime.Wasm.Engine
  alias Worker.Adapters.Runtime.Wasm.Module
  alias Worker.Domain.ExecutionResource
  alias Worker.Domain.FunctionStruct

  require Logger

  @impl true
  @spec provision(FunctionStruct.t()) :: {:ok, ExecutionResource.t()} | {:error, any()}
  def provision(function) do
    case Module.Cache.get(function.name, function.namespace) do
      %{resource: res} ->
        {:ok, %ExecutionResource{resource: res}}

      :not_found ->
        function
        |> compile_module()
        |> store_module(function.name, function.namespace)
    end
  end

  @spec compile_module(FunctionStruct.t()) :: {:ok, Module.t()} | {:error, any()}
  defp compile_module(function) do
    if function.code == nil or not is_binary(function.code) do
      {:error, :code_not_found}
    else
      Module.compile(Engine.get_handle(), function.code)
    end
  end

  @spec store_module({:ok, Module.t()} | {:error, any()}, String.t(), String.t()) ::
          {:ok, ExecutionResource.t()} | {:error, any()}
  defp store_module({:ok, %Module{resource: _} = module}, fname, ns) do
    Module.Cache.insert(fname, ns, module)
    {:ok, %ExecutionResource{resource: module}}
  end

  defp store_module(err, _, _), do: err
end

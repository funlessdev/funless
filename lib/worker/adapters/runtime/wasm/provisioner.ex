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

  alias Worker.Domain.RuntimeStruct

  require Logger

  @impl true
  @spec provision(FunctionStruct.t()) :: {:ok, RuntimeStruct.t()} | {:error, any()}
  def provision(function) do
    if function.code == nil or not is_binary(function.code) do
      {:error, :code_not_found}
    else
      {:ok, %RuntimeStruct{name: "#{function.name} wasm file", wasm: function.code}}
    end
  end
end

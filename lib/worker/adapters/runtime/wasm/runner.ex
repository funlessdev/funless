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

defmodule Worker.Adapters.Runtime.Wasm.Runner do
  @moduledoc """
    Adapter to invoke functions on WebAssembly runtimes.
  """
  @behaviour Worker.Domain.Ports.Runtime.Runner

  alias Worker.Adapters.Runtime.Wasm
  alias Worker.Domain.ExecutionResource

  require Logger

  @impl true
  def run_function(%{name: name, namespace: ns}, args, %ExecutionResource{resource: module}) do
    Logger.info("Wasm: Running #{ns}/#{name} with args #{inspect(args)}")

    string_args = Jason.encode!(args)

    engine = Wasm.Engine.get_handle()
    Wasm.Nif.run_function(engine.resource, module.resource, string_args)

    receive do
      {:ok, payload} ->
        Logger.info("Wasm: Function executed successfully")
        {:ok, Jason.decode!(payload)}

      {:exec_error, err} ->
        Logger.error("Wasm: Error during function execution: #{inspect(err)}")
        {:error, {:exec_error, err}}

      {:error, err} ->
        Logger.error("Wasm: unexpected error: #{inspect(err)}")
        {:error, err}
    end
  end
end

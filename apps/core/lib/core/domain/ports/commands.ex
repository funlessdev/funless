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

defmodule Core.Domain.Ports.Commands do
  @moduledoc """
  Port for sending commands to workers.
  """

  alias Core.Domain.FunctionStruct
  alias Core.Domain.InvokeResult

  @adapter :core |> Application.compile_env!(__MODULE__) |> Keyword.fetch!(:adapter)

  @callback send_invoke(atom(), String.t(), String.t(), map()) ::
              {:ok, InvokeResult.t()} | {:warn, :code_not_found} | {:error, :worker_error}
  @callback send_invoke_with_code(atom(), FunctionStruct.t(), map()) ::
              {:ok, InvokeResult.t()} | {:error, :worker_error}

  @doc """
  Sends an invoke command to a worker passing only the name and namespace of the function, and args.
  It requires a worker (a fully qualified name of another node with the :worker actor on), a function struct and
  (optionally empty) function arguments.
  """
  @spec send_invoke(atom(), String.t(), String.t(), map()) ::
          {:ok, InvokeResult.t()} | {:warn, :code_not_found} | {:error, :worker_error}
  defdelegate send_invoke(worker, f_name, ns, args), to: @adapter

  @doc """
  Sends an invoke command to a worker passing the name, namespace of the function and the code (either wasm file or code string).
  After this send, the worker will store the wasm file in its cache, so subsequent invokes can be done without passing the code.
  It requires a worker (a fully qualified name of another node with the :worker actor on), a function struct and
  (optionally empty) function arguments.
  """
  @spec send_invoke_with_code(atom(), FunctionStruct.t(), map()) ::
          {:ok, InvokeResult.t()} | {:error, :worker_error}
  defdelegate send_invoke_with_code(worker, function, args), to: @adapter
end

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

defmodule Core.Domain.Ports.Commands do
  @moduledoc """
  Port for sending commands to workers.
  """

  alias Data.FunctionMetadata
  alias Data.FunctionStruct
  alias Data.InvokeResult
  alias Data.ServiceMetadataStruct

  @adapter :core |> Application.compile_env!(__MODULE__) |> Keyword.fetch!(:adapter)

  @callback send_invoke(atom(), String.t(), String.t(), binary(), map(), FunctionMetadata.t()) ::
              {:ok, InvokeResult.t()} | {:error, :code_not_found, pid()} | {:error, any()}
  @callback send_invoke_with_code(atom(), pid(), FunctionStruct.t()) ::
              {:ok, InvokeResult.t()} | {:error, any()}
  @callback send_store_function(atom(), FunctionStruct.t()) ::
              :ok | {:error, :invalid_input} | {:error, any()}
  @callback send_delete_function(atom(), String.t(), String.t(), binary()) ::
              :ok | {:error, any()}
  @callback send_update_function(atom(), binary(), FunctionStruct.t()) :: :ok | {:error, any()}

  @callback send_monitor_service(atom(), ServiceMetadataStruct.t()) :: :ok | {:error, any()}

  @doc """
  Sends an invoke command to a worker passing the function name, module, hash and args.
  It requires a worker (a fully qualified name of another node with the :worker actor on) and function arguments can be empty.
  """
  @spec send_invoke(atom(), String.t(), String.t(), binary(), map(), FunctionMetadata.t()) ::
          {:ok, InvokeResult.t()} | {:error, :code_not_found, pid()} | {:error, any()}
  defdelegate send_invoke(worker, f_name, ns, hash, args, metadata), to: @adapter

  @doc """
  Sends an invoke command to a worker passing a struct with the function name, module and the code (wasm file binary).
  The command is sent directly to an handler PID in the Worker, which should have already received the
  invoke_with_code request.
  The arguments of the call are already saved Worker-side.
  The worker will store the wasm file in its cache, so subsequent invokes can be done without passing the code.
  It requires a worker (a fully qualified name of another node with the :worker actor on), a PID for the handler
  and a function struct.
  """
  @spec send_invoke_with_code(atom(), pid(), FunctionStruct.t()) ::
          {:ok, InvokeResult.t()} | {:error, any()}
  defdelegate send_invoke_with_code(worker, worker_handler, function), to: @adapter

  @doc """
  Sends a store_function command to a worker, passing a function struct, containing (at least) the function's name, module and code.
  The worker will store the wasm file locally (generally as a raw resource, without initializing).
  It requires a worker (a fully qualified name of another node with the :worker actor on) and a functions struct.
  """
  @spec send_store_function(atom(), FunctionStruct.t()) ::
          :ok | {:error, :invalid_input} | {:error, any()}
  defdelegate send_store_function(worker, function), to: @adapter

  @doc """
  Sends a delete_function command to a worker, passing the function's name and module.
  The worker should delete the function's code stored locally (both raw and pre-compiled).
  It requires a worker, the function's name, the function's module, and a hash of the function code,
  to ensure the targeted version hasn't already been updated.
  """
  @spec send_delete_function(atom(), String.t(), String.t(), binary()) :: :ok | {:error, any()}
  defdelegate send_delete_function(worker, f_name, f_mod, hash), to: @adapter

  @doc """
  Sends an update_function command to a worker, passing a function struct containing (at least) the function's name and module.
  The worker will substitute the local version of the function with the new one. In case the pre-compiled code was already cached, the new version
  will be pre-compiled and cached instead.
  It requires a worker (a fully qualified name of another node with the :worker actor on),
  the hash of the previous version of the function, and a function struct.
  """
  @spec send_update_function(atom(), binary(), FunctionStruct.t()) :: :ok | {:error, any()}
  defdelegate send_update_function(worker, prev_hash, function), to: @adapter

  # TODO write doc
  @spec send_monitor_service(atom(), [String.t()]) :: :ok | {:error, any()}
  defdelegate send_monitor_service(worker, service), to: @adapter

  @doc """
  Sends one of the commands defined in this behaviour to all specified workers, without waiting for them to respond.
  It requires a list of workers, the function to call for all workers, and the arguments for the function.
  It should immediately return :ok.

  This is a default implementation for this Port,
  and at the time of writing there's no need to make it overridable.
  """
  @spec send_to_multiple_workers([atom()], fun(), [any()]) :: :ok
  def send_to_multiple_workers(workers, command, args) do
    stream = Task.async_stream(workers, fn wrk -> apply(command, [wrk | args]) end)
    Process.spawn(fn -> Stream.run(stream) end, [])
    :ok
  end

  @doc """
  Sends one of the commands defined in this behaviour to all specified workers, and waits for their response.
  It requires a list of workers, the function to call for all workers, and the arguments for the function.
  It returns a list with the response of each of the workers.

  This is a default implementation for this Port,
  and at the time of writing there's no need to make it overridable.
  """
  @spec send_to_multiple_workers_sync([atom()], fun(), [any()]) :: [any()]
  def send_to_multiple_workers_sync(workers, command, args) do
    stream = Task.async_stream(workers, fn wrk -> apply(command, [wrk | args]) end)
    Enum.reduce(stream, [], fn response, acc -> [response | acc] end)
  end
end

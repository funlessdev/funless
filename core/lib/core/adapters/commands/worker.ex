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

defmodule Core.Adapters.Commands.Worker do
  @moduledoc """
  Adapter to send commands to a worker actor.
  Currently implemented commands: invocation.
  """
  require Logger
  alias Data.FunctionStruct
  alias Data.InvokeResult

  @behaviour Core.Domain.Ports.Commands

  # Possible replies:
  # {:ok, result}
  # {:error, atom()} mainly from the worker nifs
  # {:error, {:exec_error, msg}} an error occurred during the execution of the function
  # {:error, :code_not_found, pid()} in this case re-do the invocation passing the code.
  #                                  The call should be sent to the given handler.
  #                                  Only the send_invoke call should return this.

  @impl true
  def send_invoke(worker, name, mod, hash, args) do
    worker_addr = {:worker, worker}
    cmd = {:invoke, %{name: name, module: mod, hash: hash}, args}
    Logger.info("Sending invoke for #{mod}/#{name} to #{inspect(worker_addr)}")

    case GenServer.call(worker_addr, cmd, 60_000) do
      {:ok, result} -> {:ok, %InvokeResult{result: result}}
      {:error, :code_not_found, handler} -> {:error, :code_not_found, handler}
      {:error, err} -> {:error, err}
    end
  end

  @impl true
  def send_invoke_with_code(_worker, worker_handler, %FunctionStruct{code: _, hash: _} = func) do
    worker_addr = worker_handler
    cmd = {:invoke, func}

    Logger.info("Sending invoke with code #{func.module}/#{func.name} to #{inspect(worker_addr)}")

    case GenServer.call(worker_addr, cmd, 60_000) do
      {:ok, result} -> {:ok, %InvokeResult{result: result}}
      {:error, err} -> {:error, err}
    end
  end

  @impl true
  def send_store_function(worker, %FunctionStruct{} = function) do
    worker_addr = {:worker, worker}
    cmd = {:store_function, function}

    Logger.info(
      "Sending store_function for #{function.module}/#{function.name} to #{inspect(worker_addr)}"
    )

    GenServer.call(worker_addr, cmd, 60_000)
  end

  @impl true
  def send_delete_function(worker, name, mod, hash) do
    worker_addr = {:worker, worker}
    cmd = {:delete_function, name, mod, hash}

    Logger.info("Sending delete_function for #{mod}/#{name} to #{inspect(worker_addr)}")

    GenServer.call(worker_addr, cmd, 60_000)
  end

  @impl true
  def send_update_function(worker, prev_hash, %FunctionStruct{} = function) do
    worker_addr = {:worker, worker}
    cmd = {:update_function, prev_hash, function}

    Logger.info(
      "Sending update_function for #{function.module}/#{function.name} to #{inspect(worker_addr)}"
    )

    GenServer.call(worker_addr, cmd, 60_000)
  end

  @impl true
  def send_to_multiple_workers(workers, command, args) do
    Logger.info("Sending command multiple workers")
    stream = Task.async_stream(workers, fn wrk -> apply(command, [wrk | args]) end)
    Process.spawn(fn -> Stream.run(stream) end, [])
    :ok
  end

  @impl true
  def send_to_multiple_workers_sync(workers, command, args) do
    Logger.info("Sending command multiple workers and waiting for response")
    stream = Task.async_stream(workers, fn wrk -> apply(command, [wrk | args]) end)
    Enum.reduce(stream, [], fn response, acc -> [response | acc] end)
  end
end

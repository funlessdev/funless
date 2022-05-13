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

defmodule Worker.Worker do
  use GenServer, restart: :permanent
  alias Worker.Fn

  # Auxiliary functions

  def prepare_container(%{name: function_name, image: image_name, archive: archive_name, main_file: main_file}, from) do
    container_name = function_name <> "-funless-container"
    function = %Worker.Function{name: function_name, image: image_name, archive: archive_name, main_file: main_file}
    Fn.prepare_container(function, container_name)
    receive do
      :ok ->
        GenServer.call(:updater, {:insert, function_name, container_name})
        GenServer.reply(from, {:ok, container_name})
        {:ok, container_name}
      {:error, err} ->
        IO.puts("Error while preparing container for function #{function_name}:\n#{err}")
        GenServer.reply(from, {:error, err})
        {:error, err}
    end
  end

  def run_function(%{name: function_name}, from) do
    containers = :ets.lookup(:functions_containers, function_name)
    {:ok, {_, container_name}} = Enum.fetch(containers, 0) #TODO: might crash, handle this without timing out
    Fn.run_function(container_name)
    receive do
      {:ok, logs} ->
        IO.puts("Logs from container:\n#{logs}")
        GenServer.reply(from, {:ok, logs})
        {:ok, logs}
      {:error, err} ->
        IO.puts("Error while running function #{function_name}: #{err}")
        GenServer.reply(from, {:error, err})
        {:error, err}
    end

  end

  def cleanup(%{name: function_name}, from) do
    #TODO: differentiate cleanup all containers from cleanup single container
    containers = :ets.lookup(:functions_containers, function_name)
    {:ok, {_, container_name}} = Enum.fetch(containers, 0) #TODO: might crash, handle this without timing out
    Fn.cleanup(container_name)
    receive do
      :ok ->
        GenServer.call(:updater, {:delete, function_name, container_name})
        GenServer.reply(from, {:ok, container_name})
        :ok
      {:error, err} ->
        IO.puts("Error while cleaning up container #{container_name}: #{err}")
        GenServer.reply(from, {:error, err})
        {:error, err}
    end
  end


  # GenServer behaviour

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: :worker)
  end

  @impl true
  def init(_args) do
    # Process.flag(:trap_exit, true)
    IO.puts("worker running")
    {:ok, nil}
  end

  @impl true
  def handle_call({:prepare, function}, from, _state) do
    spawn(__MODULE__, :prepare_container, [function, from])
    {:noreply, nil}
  end

  @impl true
  def handle_call({:run, function}, from, _state) do
    spawn(__MODULE__, :run_function, [function, from])
    {:noreply, nil}
  end

  @impl true
  def handle_call({:cleanup, function}, from, _state) do
    spawn(__MODULE__, :cleanup, [function, from])
    {:noreply, nil}
  end

  # def pipeline(_args) do
  #   prepare_container("funless-node-container", "node:lts-alpine", "js/hello.tar.gz", "/opt/index.js")
  #   run_function("funless-node-container")
  #   cleanup("funless-node-container")
  # end
end

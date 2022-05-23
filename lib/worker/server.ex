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

defmodule Worker.Server do
  @moduledoc """
    Implements GenServer behaviour; the actor exposes Worker.Worker functions to other processes and nodes. No auxiliary functions are defined in this module.
  """
  use GenServer, restart: :permanent

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
    spawn(Worker.Worker, :prepare_container, [function, from])
    {:noreply, nil}
  end

  @impl true
  def handle_call({:run, function}, from, _state) do
    spawn(Worker.Worker, :run_function, [function, from])
    {:noreply, nil}
  end

  @impl true
  def handle_call({:invoke, function}, from, _state) do
    spawn(Worker.Worker, :invoke_function, [function, from])
    {:noreply, nil}
  end

  @impl true
  def handle_call({:cleanup, function}, from, _state) do
    spawn(Worker.Worker, :cleanup, [function, from])
    {:noreply, nil}
  end

end

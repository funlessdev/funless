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

defmodule Worker.Adapters.Requests.Cluster.Server do
  @moduledoc """
    Implements GenServer behaviour; the actor exposes Requests.Cluster functions to other processes and nodes.
    No auxiliary functions are defined in this module.
    All calls return immediately without replying, delegating the required work to Requests.Cluster functions.
  """
  use GenServer, restart: :permanent
  alias Worker.Adapters.Requests.Cluster

  require Logger

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: :worker)
  end

  @impl true
  def init(_args) do
    # Process.flag(:trap_exit, true)
    Logger.info("Worker Server: started")
    {:ok, nil}
  end

  @impl true
  def handle_call({:prepare, function}, from, _state) do
    Logger.info("Received prepare request for #{function.name}.")
    spawn(Cluster, :prepare, [function, from])
    {:noreply, nil}
  end

  @impl true
  def handle_call({:invoke, function}, from, _state) do
    Logger.info("Received invocation request for #{function.name}.")
    spawn(Cluster, :invoke, [function, %{}, from])
    {:noreply, nil}
  end

  @impl true
  def handle_call({:invoke, function, args}, from, _state) do
    Logger.info("Received invocation request for #{function.name} with args.")
    spawn(Cluster, :invoke, [function, args, from])
    {:noreply, nil}
  end

  @impl true
  def handle_call({:cleanup, function}, from, _state) do
    Logger.info("Received cleanup request for #{function.name}.")
    spawn(Cluster, :cleanup, [function, from])
    {:noreply, nil}
  end

  @impl true
  def handle_call({:cleanup_all, function}, from, _state) do
    Logger.info("Received cleanup_all request for #{function.name}.")
    spawn(Cluster, :cleanup_all, [function, from])
    {:noreply, nil}
  end
end

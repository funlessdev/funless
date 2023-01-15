# Copyright 2022 Giuseppe De Palma, Matteo Trentin
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

defmodule Core.Adapters.DataSinks.Manager do
  @moduledoc """
  Adapter to handle Data Sinks processes.
  """
  @main_supervisor Core.Adapters.DataSinks.DynamicSupervisor
  @registry Core.Adapters.DataSinks.Registry

  @behaviour Core.Domain.Ports.DataSinks.Manager

  alias Core.Adapters.DataSinks.MongoDB
  alias Core.Domain.Ports.DataSinks.Manager
  alias Data.DataSink

  require Logger

  @impl true
  def get_all(module, function) do
    name = "#{Atom.to_string(@main_supervisor)}.#{module}/#{function}"

    case Registry.lookup(@registry, name) do
      [] ->
        {:error, :not_found}

      [{pid, _}] ->
        {:ok,
         pid
         |> DynamicSupervisor.which_children()
         |> Enum.map(fn {_, child, _, _} -> child end)
         |> Enum.filter(&(&1 != :restarting))}
    end
  end

  @impl true
  def plug(%{name: function, module: module}, %DataSink{
        type: sink_type,
        params: params
      }) do
    with {:ok, sink} <- Manager.which_data_sink(sink_type) do
      Logger.debug(
        "DataSinkManager: plugging #{module}/#{function} with #{sink_type}: #{inspect(params)}"
      )

      # dedicated DynamicSupervisor name for this function's Data Sinks
      name = "#{Atom.to_string(@main_supervisor)}.#{module}/#{function}"
      supervisor = {:via, Registry, {@registry, name}}

      @registry
      |> Registry.lookup(supervisor)
      |> start_sink_process(supervisor, sink, params)
    end
  end

  # if the supervisor does not exist, first start it and then the child
  defp start_sink_process([], supervisor, sink, args) do
    DynamicSupervisor.start_child(
      @main_supervisor,
      {DynamicSupervisor,
       strategy: :one_for_one, max_restarts: 5, max_seconds: 5, name: supervisor}
    )

    start_sink(supervisor, sink, args)
  end

  # if the supervisor exists, just add the child
  defp start_sink_process([{pid, _}], supervisor, sink, args) do
    if Process.alive?(pid) do
      start_sink(supervisor, sink, args)
    else
      {:error, :supervisor_stopping}
    end
  end

  defp start_sink(supervisor, sink, args) do
    result =
      DynamicSupervisor.start_child(
        supervisor,
        {sink, args}
      )

    case result do
      {:ok, _pid} -> :ok
      {:ok, _pid, _info} -> :ok
      :ignore -> {:error, :ignore}
      {:error, err} -> {:error, err}
    end
  end

  @impl true
  def which_data_sink(sink_type) do
    case sink_type do
      "mongodb" -> {:ok, MongoDB}
      _ -> {:error, :not_implemented}
    end
  end

  @impl true
  def unplug(%{name: function, module: module}) do
    supervisor = "#{Atom.to_string(@main_supervisor)}.#{module}/#{function}"

    case Registry.lookup(@registry, supervisor) do
      [] ->
        {:error, :not_found}

      [{pid, _}] ->
        DynamicSupervisor.terminate_child(@main_supervisor, pid)
    end
  end
end

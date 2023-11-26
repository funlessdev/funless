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

defmodule CoreWeb.FunctionController do
  use CoreWeb, :controller

  alias Core.Domain.{
    DataSink,
    Events,
    Functions,
    Invoker,
    Modules,
    Nodes,
    WorkerResourceHandler
  }

  alias Core.Schemas.Function
  alias Data.FunctionStruct
  alias Data.InvokeParams

  require Logger

  action_fallback(CoreWeb.FallbackController)

  def show(conn, %{"module_name" => mod_name, "function_name" => name}) do
    with {:ok, %Function{} = function} <- retrieve_fun_in_mod(name, mod_name) do
      render(conn, :show, function: function)
    end
  end

  def invoke(conn, %{"module_name" => mod_name, "function_name" => fun_name} = params) do
    ivk = %InvokeParams{
      function: fun_name,
      module: mod_name,
      args: params["args"] || %{}
    }

    with {:ok, res} <- Invoker.invoke(ivk) do
      json(conn, %{data: res})
    end
  end

  def create(
        conn,
        %{
          "module_name" => module_name,
          "name" => fn_name,
          "code" => %Plug.Upload{path: tmp_path}
        } = params
      ) do
    events_req = params |> Map.get("events", nil) |> parse_requested_events_sinks()
    sinks_req = params |> Map.get("sinks", nil) |> parse_requested_events_sinks()

    # wait for all workers to receive the code; true by default
    wait_for_workers = params |> Map.get("wait_for_workers", true)

    if events_req == :error or sinks_req == :error do
      Logger.error("Function Controller: received invalid JSON. Aborting function creation.")
      {:error, :bad_params}
    else
      with {:ok, code} <- File.read(tmp_path),
           {:ok, module} <- Modules.get_module_by_name(module_name) do
        case %{"name" => fn_name, "code" => code}
             |> Map.put_new("module_id", module.id)
             |> Functions.create_function() do
          {:ok, %Function{} = function} ->
            Logger.info(
              "Function Controller: function #{module_name}/#{fn_name} created successfully."
            )

            event_results = Events.connect_events(fn_name, module_name, events_req)
            sinks_results = DataSink.plug_data_sinks(fn_name, module_name, sinks_req)

            store_on_create()
            |> send_function_to_workers(fn_name, module_name, code)
            |> do_wait_for_workers(wait_for_workers)

            {status, render_params} =
              build_render_params(%{function: function}, event_results, sinks_results, :created)

            conn
            |> put_status(status)
            |> render(:show, render_params)

          {:error, %{errors: [function_module_index_constraint: {"has already been taken", _}]}} ->
            Logger.error("Function Controller: #{module_name}/#{fn_name} already exists.")
            {:error, :conflict}

          e ->
            Logger.error(
              "Function Controller: error while creating #{module_name}/#{fn_name}: #{inspect(e)}."
            )

            e
        end
      end
    end
  end

  def create(_conn, _) do
    {:error, :bad_params}
  end

  def update(
        conn,
        %{
          "module_name" => module_name,
          "function_name" => fn_name,
          "code" => %Plug.Upload{path: tmp_path},
          "name" => new_name
        } = params
      ) do
    events_req = params |> Map.get("events", nil) |> parse_requested_events_sinks()
    sinks_req = params |> Map.get("sinks", nil) |> parse_requested_events_sinks()

    if events_req == :error or sinks_req == :error do
      Logger.error("Function Controller: received invalid JSON. Aborting function update.")
      {:error, :bad_params}
    else
      with {:ok, code} <- File.read(tmp_path),
           {:ok, %Function{} = function} <- retrieve_fun_in_mod(fn_name, module_name),
           {:ok, %Function{} = function} <-
             Functions.update_function(function, %{"name" => new_name, "code" => code}) do
        event_results = Events.update_events(fn_name, module_name, events_req)
        sinks_results = DataSink.update_data_sinks(fn_name, module_name, sinks_req)

        {status, render_params} =
          build_render_params(%{function: function}, event_results, sinks_results)

        conn
        |> put_status(status)
        |> render(:show, render_params)
      end
    end
  end

  def update(_conn, _) do
    {:error, :bad_params}
  end

  def delete(conn, %{"module_name" => mod_name, "function_name" => name}) do
    with {:ok, %Function{} = function} <- retrieve_fun_in_mod(name, mod_name),
         {:ok, %Function{}} <- Functions.delete_function(function),
         :ok <- Events.disconnect_events(name, mod_name),
         :ok <- DataSink.unplug_data_sink(name, mod_name) do
      send_resp(conn, :no_content, "")
    end
  end

  @spec retrieve_fun_in_mod(String.t(), String.t()) :: {:ok, term()} | {:error, :not_found}
  defp retrieve_fun_in_mod(fname, mod_name) do
    case Functions.get_by_name_in_mod!(fname, mod_name) do
      [] -> {:error, :not_found}
      [function] -> {:ok, function}
    end
  end

  @spec parse_requested_events_sinks(String.t() | nil) :: term() | nil | :error
  defp parse_requested_events_sinks(s) when is_nil(s) or s == "", do: nil

  defp parse_requested_events_sinks(s) do
    case Jason.decode(s) do
      {:ok, e} -> e
      {:error, _} -> :error
    end
  end

  defp build_render_params(render_params, events, sinks, default_status \\ :ok) do
    event_errors? = Enum.any?(events, &(&1 != :ok))
    sinks_errors? = Enum.any?(sinks, &(&1 != :ok))

    status =
      if event_errors? or sinks_errors? do
        :multi_status
      else
        default_status
      end

    {status,
     render_params
     |> Map.put(:events, events)
     |> Map.put(:sinks, sinks)}
  end

  defp send_function_to_workers(true, function_name, module, code) do
    workers = Nodes.worker_nodes()

    function =
      struct(FunctionStruct, %{
        name: function_name,
        module: module,
        code: code
      })

    Logger.info("Function controller: sending code to workers")

    Task.async_stream(workers, fn wrk -> WorkerResourceHandler.store_function(wrk, function) end)
  end

  defp send_function_to_workers(false, _, _, _) do
    []
  end

  defp do_wait_for_workers([], _) do
    :ok
  end

  defp do_wait_for_workers(stream, true) do
    {_pid, ref} = Process.spawn(fn -> Stream.run(stream) end, [:monitor])

    receive do
      {:DOWN, ^ref, _, _, _} ->
        Logger.info("Function controller: code sent to all workers")
        :ok

      {:DOWN, ^ref, _, _, reason} ->
        Logger.warn(
          "Something went wrong while sending code to all workers (process exited with reason #{reason})"
        )

        :ok
    end
  end

  defp do_wait_for_workers(stream, false) do
    Stream.run(stream)
  end

  defp store_on_create do
    :core
    |> Application.fetch_env!(:store_on_create)
    |> then(fn v -> String.downcase(v) == "true" end)
  end
end

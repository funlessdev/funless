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

  alias Core.Domain.CAPPScripts

  alias Core.Domain.{
    APPScripts,
    DataSink,
    Events,
    Functions,
    Invoker,
    Modules,
    Nodes,
    Policies.Parsers
  }

  alias Core.Domain.Ports.Commands
  alias Core.FunctionsMetadata
  alias Core.Schemas.FunctionMetadata

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
    config =
      case params |> Map.get("scheduling") do
        nil ->
          %Data.Configurations.Empty{}

        %{"language" => "none"} ->
          %Data.Configurations.Empty{}

        %{"language" => "app", "script" => script_name} ->
          %{name: ^script_name, script: script} = APPScripts.get_app_script_by_name(script_name)

          Parsers.APP.from_string_keys(script)

        %{"language" => "capp", "script" => script_name} ->
          %{name: ^script_name, script: script} = CAPPScripts.get_capp_script_by_name(script_name)

          Parsers.CAPP.from_string_keys(script)
      end

    ivk = %InvokeParams{
      function: fun_name,
      module: mod_name,
      args: params["args"] || %{},
      config: config
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
    # wait for all workers to receive the code; true by default
    Logger.info("Function Controller: received params #{inspect(params)}.")

    with {:ok, events_req} <-
           params |> Map.get("events", nil) |> parse_requested_events_sinks(),
         {:ok, sinks_req} <- params |> Map.get("sinks", nil) |> parse_requested_events_sinks(),
         {:ok, metadata} <- params |> Map.get("metadata", nil) |> parse_metadata(),
         {:ok, code} <- File.read(tmp_path),
         {:ok, module} <- Modules.get_module_by_name(module_name),
         {:ok, %Function{} = function} <-
           %{"name" => fn_name, "code" => code}
           |> Map.put_new("module_id", module.id)
           |> Functions.create_function(),
         {:ok, _} <-
           metadata
           |> Map.from_struct()
           |> Map.put_new(:function_id, function.id)
           |> FunctionsMetadata.create_function_metadata() do
      wait_for_workers = params |> Map.get("wait_for_workers", true)

      Logger.info(
        "Function Controller: #{module_name}/#{fn_name} created successfully with metadata #{inspect(metadata)}."
      )

      Commands.send_to_multiple_workers_sync(
        Nodes.worker_nodes(),
        &Commands.send_monitor_service/2,
        [
          metadata.miniSL_services
        ]
      )

      event_results = Events.connect_events(fn_name, module_name, events_req)
      sinks_results = DataSink.plug_data_sinks(fn_name, module_name, sinks_req)

      if store_on_create() do
        workers = Nodes.worker_nodes()

        func_struct =
          struct(FunctionStruct, %{
            name: fn_name,
            module: module_name,
            code: code,
            hash: function.hash,
            metadata: metadata
          })

        if wait_for_workers do
          Commands.send_to_multiple_workers_sync(workers, &Commands.send_store_function/2, [
            func_struct
          ])
        else
          Commands.send_to_multiple_workers(workers, &Commands.send_store_function/2, [
            func_struct
          ])
        end
      end

      {status, render_params} =
        build_render_params(%{function: function}, event_results, sinks_results, :created)

      conn
      |> put_status(status)
      |> render(:show, render_params)
    else
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
    with {:ok, events_req} <- params |> Map.get("events", nil) |> parse_requested_events_sinks(),
         {:ok, sinks_req} <- params |> Map.get("sinks", nil) |> parse_requested_events_sinks(),
         {:ok, new_metadata} <- params |> Map.get("metadata", nil) |> parse_metadata(),
         {:ok, code} <- File.read(tmp_path),
         {:ok, %Function{} = function} <- retrieve_fun_in_mod(fn_name, module_name),
         {:ok, %Function{} = function} <-
           Functions.update_function(function, %{"name" => new_name, "code" => code}),
         {:ok, %FunctionMetadata{} = metadata} <-
           FunctionsMetadata.get_function_metadata_by_function_id(function.id),
         {:ok, _} <-
           FunctionsMetadata.update_function_metadata(metadata, new_metadata |> Map.from_struct()) do
      # wait for all workers to receive the code; true by default
      wait_for_workers = params |> Map.get("wait_for_workers", true)
      event_results = Events.update_events(fn_name, module_name, events_req)
      sinks_results = DataSink.update_data_sinks(fn_name, module_name, sinks_req)

      workers = Nodes.worker_nodes()
      prev_hash = function.hash

      func_struct =
        struct(FunctionStruct, %{
          name: fn_name,
          module: module_name,
          code: code,
          hash: function.hash
        })

      if wait_for_workers do
        Commands.send_to_multiple_workers_sync(workers, &Commands.send_update_function/3, [
          prev_hash,
          func_struct
        ])
      else
        Commands.send_to_multiple_workers(workers, &Commands.send_update_function/3, [
          prev_hash,
          func_struct
        ])
      end

      {status, render_params} =
        build_render_params(%{function: function}, event_results, sinks_results)

      conn
      |> put_status(status)
      |> render(:show, render_params)
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
      # wait for all workers to receive the code; true by default
      workers = Nodes.worker_nodes()

      # Delete requests do not wait for a response, since we are being optimistic anyway
      # (create-invoke-delete requests can interleave, resulting in the old version of a function being invoked)
      # Therefore, there is not point in adding extra waiting time.
      # We rely on the function's hash to ensure it's the latest version on the worker's side
      Commands.send_to_multiple_workers(workers, &Commands.send_delete_function/4, [
        name,
        mod_name,
        function.hash
      ])

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

  @spec parse_requested_events_sinks(String.t() | nil) ::
          {:ok, nil} | {:ok, term()} | {:error, :bad_params}
  defp parse_requested_events_sinks(s) when is_nil(s) or s == "", do: {:ok, nil}

  defp parse_requested_events_sinks(s) do
    case Jason.decode(s) do
      {:ok, e} ->
        {:ok, e}

      {:error, _} ->
        Logger.error("Function Controller: received invalid JSON while parsing events and sinks.")
        {:error, :bad_params}
    end
  end

  defp parse_metadata(m) when is_nil(m) or m == "", do: {:ok, %Data.FunctionMetadata{}}

  defp parse_metadata(m) do
    Logger.info("Function Controller: received metadata #{inspect(m)}. Parsing...")

    case Jason.decode(m) do
      {:ok, json_metadata} ->
        Logger.info("Decoded metadata: #{inspect(json_metadata)}.")
        # metadata = struct!(Data.FunctionMetadata, json_metadata) Not working for some reason
        metadata = %Data.FunctionMetadata{
          tag: Map.get(json_metadata, "tag", nil),
          capacity: Map.get(json_metadata, "capacity", -1),
          params: Map.get(json_metadata, "params", []),
          main_func: Map.get(json_metadata, "main_func", nil),
          miniSL_services:
            Map.get(json_metadata, "miniSL_services", []) |> Enum.map(&parse_svc(&1)),
          miniSL_equation: Map.get(json_metadata, "miniSL_equation", [])
        }

        Logger.info("Created metadata struct: #{inspect(metadata)}.")
        {:ok, metadata}

      {:error, _} ->
        Logger.error(
          "Function Controller: received invalid JSON while parsing function metadata."
        )

        {:error, :bad_params}
    end
  end

  defp parse_svc(s) do
    {
      s |> Map.get("method", "get") |> String.to_existing_atom(),
      s |> Map.get("url", ""),
      s |> Map.get("request_fields", []) |> Enum.map(&parse_params(&1)),
      s |> Map.get("response_fields", []) |> Enum.map(&parse_params(&1))
    }
  end

  defp parse_params(%{"s_name" => n, "s_type" => t}) do
    {
      n,
      t |> String.to_existing_atom()
    }
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

  defp store_on_create do
    :core
    |> Application.fetch_env!(:store_on_create)
    |> then(fn v -> String.downcase(v) == "true" end)
  end
end

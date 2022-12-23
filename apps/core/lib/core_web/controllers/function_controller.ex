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

defmodule CoreWeb.FunctionController do
  use CoreWeb, :controller

  alias Core.Domain.{Functions, Invoker, Modules}
  alias Core.Schemas.{Function, Module}
  alias Data.InvokeParams

  action_fallback(CoreWeb.FallbackController)

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
    with {:ok, code} <- File.read(tmp_path),
         %Module{} = module <- Modules.get_module_by_name!(module_name),
         {:ok, %Function{} = function} <-
           %{"name" => fn_name, "code" => code}
           |> Map.put_new("module_id", module.id)
           |> Functions.create_function() do
      # TODO: update API spec with new possible return code and object

      event_results =
        Core.Domain.Events.connect_events(fn_name, module_name, Map.get(params, "events"))

      event_errors? =
        event_results
        |> Enum.any?(fn e ->
          e != :ok
        end)

      if !event_errors? do
        conn
        |> put_status(:created)
        |> render("show.json", function: function)
      else
        conn
        |> put_status(:multi_status)
        |> render("show.json", function: function, events: event_results)
      end
    end
  end

  def create(_conn, _) do
    {:error, :bad_params}
  end

  def show(conn, %{"module_name" => mod_name, "function_name" => name}) do
    with {:ok, %Function{} = function} <- retrieve_fun_in_mod(name, mod_name) do
      render(conn, "show.json", function: function)
    end
  end

  def update(
        conn,
        %{
          "module_name" => mod_name,
          "function_name" => name,
          "code" => %Plug.Upload{path: tmp_path},
          "name" => new_name
        } = params
      ) do
    # TODO: update API spec with new possible return type and object

    with {:ok, code} <- File.read(tmp_path),
         {:ok, %Function{} = function} <- retrieve_fun_in_mod(name, mod_name),
         {:ok, %Function{} = function} <-
           Functions.update_function(function, %{"name" => new_name, "code" => code}) do
      event_results =
        Core.Domain.Events.update_events(new_name, mod_name, Map.get(params, "events"))

      event_errors? =
        event_results
        |> Enum.any?(fn e ->
          e != :ok
        end)

      if !event_errors? do
        conn
        |> render("show.json", function: function)
      else
        conn
        |> put_status(:multi_status)
        |> render("show.json", function: function, events: event_results)
      end
    end
  end

  def update(_conn, _) do
    {:error, :bad_params}
  end

  def delete(conn, %{"module_name" => mod_name, "function_name" => name}) do
    with {:ok, %Function{} = function} <- retrieve_fun_in_mod(name, mod_name),
         {:ok, %Function{}} <- Functions.delete_function(function),
         :ok <- Core.Domain.Events.disconnect_events(name, mod_name) do
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
end

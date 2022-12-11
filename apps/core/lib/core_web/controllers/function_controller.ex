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

  alias Core.Domain.{Functions, Modules}
  alias Core.Schemas.{Function, Module}

  action_fallback(CoreWeb.FallbackController)

  def create(conn, %{"module_name" => module_name, "function" => params}) do
    with %Module{} = module <- Modules.get_module_by_name!(module_name),
         {:ok, %Function{} = function} <-
           params
           |> Map.put_new("module_id", module.id)
           |> Functions.create_function() do
      conn
      |> put_status(:created)
      |> render("show.json", function: function)
    end
  end

  def show(conn, %{"module_name" => mod_name, "function_name" => name}) do
    with {:ok, %Function{} = function} <- retrieve_fun_in_mod(name, mod_name) do
      render(conn, "show.json", function: function)
    end
  end

  def update(conn, %{
        "module_name" => mod_name,
        "function_name" => name,
        "function" => function_params
      }) do
    with {:ok, %Function{} = function} <- retrieve_fun_in_mod(name, mod_name),
         {:ok, %Function{} = function} <- Functions.update_function(function, function_params) do
      render(conn, "show.json", function: function)
    end
  end

  def delete(conn, %{"module_name" => mod_name, "function_name" => name}) do
    with {:ok, %Function{} = function} <- retrieve_fun_in_mod(name, mod_name),
         {:ok, %Function{}} <- Functions.delete_function(function) do
      send_resp(conn, :no_content, "")
    end
  end

  @spec retrieve_fun_in_mod(String.t(), String.t()) :: {:ok, Function.t()} | {:error, :not_found}
  defp retrieve_fun_in_mod(fname, mod_name) do
    case Functions.get_by_name_in_mod!(fname, mod_name) do
      [] -> {:error, :not_found}
      [function] -> {:ok, function}
    end
  end
end

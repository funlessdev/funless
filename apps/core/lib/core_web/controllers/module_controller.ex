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

defmodule CoreWeb.ModuleController do
  use CoreWeb, :controller

  alias Core.Domain.Modules
  alias Core.Schemas.Module

  action_fallback(CoreWeb.FallbackController)

  def index(conn, _params) do
    modules = Modules.list_modules()
    render(conn, "index.json", modules: modules)
  end

  def create(conn, %{"module" => module_params}) do
    with {:ok, %Module{} = module} <- Modules.create_module(module_params) do
      conn
      |> put_status(:created)
      |> render("show.json", module: module)
    end
  end

  def show_functions(conn, %{"module_name" => name}) do
    functions = Modules.get_functions_in_module!(name)
    render(conn, "show_functions.json", %{module_name: name, functions: functions})
  end

  def update(conn, %{"module_name" => name, "module" => module_params}) do
    with {:ok, module} <- Modules.get_module_by_name(name),
         {:ok, %Module{} = module} <- Modules.update_module(module, module_params) do
      render(conn, "show.json", module: module)
    end
  end

  def delete(conn, %{"module_name" => name}) do
    with {:ok, module} <- Modules.get_module_by_name(name),
         {:ok, %Module{}} <- Modules.delete_module(module) do
      send_resp(conn, :no_content, "")
    end
  end
end

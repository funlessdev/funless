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

  alias Core.Domain.Functions
  alias Core.Schemas.Function

  action_fallback(CoreWeb.FallbackController)

  def index(conn, _params) do
    functions = Functions.list_functions()
    render(conn, "index.json", functions: functions)
  end

  def create(conn, %{"function" => function_params}) do
    with {:ok, %Function{} = function} <- Functions.create_function(function_params) do
      conn
      |> put_status(:created)
      |> render("show.json", function: function)
    end
  end

  def show(conn, %{"id" => id}) do
    function = Functions.get_function!(id)
    render(conn, "show.json", function: function)
  end

  def update(conn, %{"id" => id, "function" => function_params}) do
    function = Functions.get_function!(id)

    with {:ok, %Function{} = function} <- Functions.update_function(function, function_params) do
      render(conn, "show.json", function: function)
    end
  end

  def delete(conn, %{"id" => id}) do
    function = Functions.get_function!(id)

    with {:ok, %Function{}} <- Functions.delete_function(function) do
      send_resp(conn, :no_content, "")
    end
  end
end

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

defmodule CoreWeb.ModuleView do
  use CoreWeb, :view

  alias CoreWeb.FunctionView
  alias CoreWeb.ModuleView

  def render("index.json", %{modules: modules}) do
    %{data: render_many(modules, ModuleView, "module.json")}
  end

  def render("show.json", %{module: module}) do
    %{data: render_one(module, ModuleView, "module.json")}
  end

  def render("show_functions.json", %{module_name: name, functions: functions}) do
    %{data: %{name: name, functions: render_many(functions, FunctionView, "function.json")}}
  end

  def render("module.json", %{module: module}) do
    %{
      name: module.name
    }
  end
end

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

defmodule CoreWeb.ErrorView do
  use CoreWeb, :view

  # If you want to customize a particular status code
  # for a certain format, you may uncomment below.
  # def render("500.json", _assigns) do
  #   %{errors: %{detail: "Internal Server Error"}}
  # end

  # By default, Phoenix returns the status message from
  # the template name. For example, "404.json" becomes
  # "Not Found".
  def template_not_found(template, _assigns) do
    %{errors: %{detail: Phoenix.Controller.status_message_from_template(template)}}
  end

  def render("400.json", _assigns) do
    %{errors: %{detail: "Failed to perform operation: bad request"}}
  end

  def render("function_not_found.json", _assigns) do
    %{errors: %{detail: "Failed to invoke function: not found in given namespace"}}
  end

  def render("db_aborted.json", %{action: action, reason: reason}) do
    message = "Failed to #{action} function: database error because #{reason}"
    %{errors: %{detail: message}}
  end

  def render("no_workers.json", _assigns) do
    %{errors: %{detail: "Failed to invoke function: no worker available"}}
  end

  def render("worker_error.json", _assigns) do
    %{errors: %{detail: "Failed to invoke function: worker error"}}
  end
end

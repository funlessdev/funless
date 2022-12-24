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

defmodule CoreWeb.FunctionView do
  use CoreWeb, :view
  alias CoreWeb.FunctionView

  def render("index.json", %{functions: functions}) do
    %{data: render_many(functions, FunctionView, "function.json")}
  end

  def render("show.json", %{data: %{function: _function, events: _events} = content}) do
    %{
      data: render_one(content, FunctionView, "function_events.json", as: :data)
    }
  end

  def render("show.json", %{function: function}) do
    %{data: render_one(function, FunctionView, "function.json")}
  end

  def render("function_events.json", %{data: %{function: function, events: events}}) do
    successful = events |> Enum.count(fn e -> e == :ok end)
    failed = length(events) - successful

    %{
      name: function.name,
      events: render_many(events, FunctionView, "event.json", as: :result),
      metadata: %{
        successful: successful,
        failed: failed,
        total: length(events)
      }
    }
  end

  def render("function.json", %{function: function}) do
    %{
      name: function.name
    }
  end

  def render("event.json", %{result: :ok}) do
    %{
      status: "success"
    }
  end

  def render("event.json", %{result: {:error, err}}) do
    %{
      status: "error",
      message: "#{inspect(err)}"
    }
  end
end

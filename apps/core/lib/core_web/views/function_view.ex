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

  # If I receive both sinks and events
  def render("show.json", %{
        data: %{function: _function, events: _events, sinks: _sinks} = content
      }) do
    %{
      data: render_one(content, FunctionView, "function_events_sinks.json", as: :data)
    }
  end

  # If I receive only the sinks
  def render("show.json", %{data: %{function: _function, sinks: _sinks} = content}) do
    %{
      data: render_one(content, FunctionView, "function_sinks.json", as: :data)
    }
  end

  # If I receive only the events
  def render("show.json", %{data: %{function: _function, events: _events} = content}) do
    %{
      data: render_one(content, FunctionView, "function_events.json", as: :data)
    }
  end

  # If I receive neither events nor sinks
  def render("show.json", %{function: function}) do
    %{data: render_one(function, FunctionView, "function.json")}
  end

  def render("function_sinks.json", %{
        data: %{function: function, sinks: sinks}
      }) do
    successful_sinks = sinks |> Enum.count(fn e -> e == :ok end)
    failed_sinks = length(sinks) - successful_sinks

    %{
      name: function.name,
      sinks: render_many(sinks, FunctionView, "event.json", as: :result),
      sinks_metadata: %{
        successful: successful_sinks,
        failed: failed_sinks,
        total: length(sinks)
      }
    }
  end

  def render("function_events.json", %{data: %{function: function, events: events}}) do
    successful_events = events |> Enum.count(fn e -> e == :ok end)
    failed_events = length(events) - successful_events

    %{
      name: function.name,
      events: render_many(events, FunctionView, "event.json", as: :result),
      events_metadata: %{
        successful: successful_events,
        failed: failed_events,
        total: length(events)
      }
    }
  end

  def render("function_events_sinks.json", %{
        data: %{function: function, events: events, sinks: sinks}
      }) do
    successful_events = events |> Enum.count(fn e -> e == :ok end)
    failed_events = length(events) - successful_events

    successful_sinks = sinks |> Enum.count(fn e -> e == :ok end)
    failed_sinks = length(sinks) - successful_sinks

    %{
      name: function.name,
      events: render_many(events, FunctionView, "event.json", as: :result),
      sinks: render_many(sinks, FunctionView, "event.json", as: :result),
      events_metadata: %{
        successful: successful_events,
        failed: failed_events,
        total: length(events)
      },
      sinks_metadata: %{
        successful: successful_sinks,
        failed: failed_sinks,
        total: length(sinks)
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

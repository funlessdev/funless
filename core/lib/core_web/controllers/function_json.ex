defmodule CoreWeb.FunctionJSON do
  # @doc """
  # Renders a list of functions.
  # """
  # def index(%{functions: functions}) do
  #   %{data: for(function <- functions, do: data(function))}
  # end

  alias Core.Schemas.Function

  @doc """
  Renders a single function.
  """
  # If we receive only the sinks
  def show(%{function: _function, sinks: [_ | _], events: []} = content) do
    %{data: function_sinks(content)}
  end

  # If we receive only the events
  def show(%{function: _function, events: [_ | _], sinks: []} = content) do
    %{data: function_events(content)}
  end

  # If we receive events and sinks but they are empty
  def show(%{function: function, events: [], sinks: []}) do
    %{data: just_function(function)}
  end

  # If we receive both sinks and events
  def show(%{function: _function, events: _events, sinks: _sinks} = content) do
    %{data: function_events_sinks(content)}
  end

  # If we receive only the function
  def show(%{function: function}) do
    %{data: just_function(function)}
  end

  def function_sinks(%{function: function, sinks: sinks}) do
    successful_sinks = sinks |> Enum.count(fn e -> e == :ok end)
    failed_sinks = length(sinks) - successful_sinks

    %{
      name: function.name,
      sinks: for(s <- sinks, do: event(s)),
      sinks_metadata: %{
        successful: successful_sinks,
        failed: failed_sinks,
        total: length(sinks)
      }
    }
  end

  def function_events(%{function: function, events: events}) do
    successful_events = events |> Enum.count(fn e -> e == :ok end)
    failed_events = length(events) - successful_events

    %{
      name: function.name,
      events: for(e <- events, do: event(e)),
      events_metadata: %{
        successful: successful_events,
        failed: failed_events,
        total: length(events)
      }
    }
  end

  def function_events_sinks(%{function: function, events: events, sinks: sinks}) do
    successful_events = events |> Enum.count(fn e -> e == :ok end)
    failed_events = length(events) - successful_events

    successful_sinks = sinks |> Enum.count(fn e -> e == :ok end)
    failed_sinks = length(sinks) - successful_sinks

    %{
      name: function.name,
      events: for(e <- events, do: event(e)),
      sinks: for(s <- sinks, do: event(s)),
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

  def just_function(%Function{} = function) do
    %{name: function.name}
  end

  def event(:ok) do
    %{
      status: "success"
    }
  end

  def event({:error, err}) do
    %{
      status: "error",
      message: "#{inspect(err)}"
    }
  end
end

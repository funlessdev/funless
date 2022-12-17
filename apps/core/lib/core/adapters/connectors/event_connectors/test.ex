defmodule Core.Adapters.Connectors.EventConnectors.Test do
  @moduledoc """
  Event Connector for testing purposes.
  """
  use GenServer

  def start_link(params) do
    GenServer.start_link(__MODULE__, params)
  end

  def init(_params) do
    {:ok, nil}
  end
end

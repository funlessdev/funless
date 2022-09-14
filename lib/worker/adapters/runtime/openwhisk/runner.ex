defmodule Worker.Adapters.Runtime.OpenWhisk.Runner do
  @behaviour Worker.Domain.Ports.Runtime.Runner

  @impl true
  def run_function(fl_function, args, runtime) do
    {:ok, "hello"}
  end
end

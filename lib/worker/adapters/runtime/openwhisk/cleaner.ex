defmodule Worker.Adapters.Runtime.OpenWhisk.Cleaner do
  @behaviour Worker.Domain.Ports.Runtime.Cleaner

  @impl true
  def cleanup(runtime) do
    {:ok, runtime}
  end
end

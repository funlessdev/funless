defmodule Worker.Adapters.Runtime.Wasm.Cleaner do
  @moduledoc """
    Adapter for WebAssembly runtime removal.
    Since we are running no permanent container, the removal is not necessary; as such, no operation is performed,
    and the runtime is simply returned to the caller.
  """
  @behaviour Worker.Domain.Ports.Runtime.Cleaner

  @impl true
  def cleanup(runtime) do
    {:ok, runtime}
  end
end

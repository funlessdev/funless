defmodule Worker.Adapters.Runtime.Wasm.Runner do
  @moduledoc """
    Adapter to invoke functions on WebAssembly runtimes.
  """
  @behaviour Worker.Domain.Ports.Runtime.Runner

  alias Worker.Adapters.Runtime.Wasm.Nif

  require Logger

  @impl true
  def run_function(_fl_function, args, %{wasm: wasm} = _runtime) do
    Logger.info("Wasm: Running function on WebAssembly runtime")

    Nif.run_function(wasm, args)

    receive do
      {:ok, payload} ->
        Logger.info("Wasm: Function executed successfully")
        {:ok, Jason.decode!(payload)}

      {:error, err} ->
        Logger.error("Wasm: Error while running function: #{inspect(err)}")
        {:error, err}
    end
  end
end

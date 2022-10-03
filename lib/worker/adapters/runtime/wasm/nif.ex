defmodule Worker.Adapters.Runtime.Wasm.Nif do
  @moduledoc """
  NIFs used to interact with WebAssembly runtimes.
  """
  use Rustler, otp_app: :worker, crate: :fn_wasm

  #   Runs the function with the given code, using the underlying WebAssembly runtime.
  #   ## Parameters
  #     - _function_code: wasm code of the function to be run
  #     - _ args: arguments passed to the function
  @doc false
  def run_function(_function_code, _args) do
    :erlang.nif_error(:nif_not_loaded)
  end
end

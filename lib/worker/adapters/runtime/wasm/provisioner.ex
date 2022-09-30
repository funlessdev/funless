defmodule Worker.Adapters.Runtime.Wasm.Provisioner do
  @moduledoc """
    Adapter for WebAssembly runtime creation. As the
  """
  @behaviour Worker.Domain.Ports.Runtime.Provisioner

  alias Worker.Domain.FunctionStruct
  alias Worker.Domain.RuntimeStruct

  require Logger

  @impl true
  def prepare(%FunctionStruct{code: code} = _function, runtime_name) do
    {:ok, %RuntimeStruct{name: runtime_name, wasm: code}}
  end

  def prepare(_function, _runtime_name) do
    {:error, :no_code_provided}
  end
end

defmodule Worker.Adapters.Runtime.Wasm.Engine do
  defstruct [
    # The actual NIF Resource.
    resource: nil,
    # Normally the compiler will happily do stuff like inlining the
    # resource in attributes. This will convert the resource into an
    # empty binary with no warning. This will make that harder to
    # accidentaly do.
    reference: nil
  ]

  def wrap_resource(resource) do
    %__MODULE__{
      resource: resource,
      reference: make_ref()
    }
  end
end

defimpl Inspect, for: Worker.Adapters.Runtime.Wasm.Engine do
  import Inspect.Algebra

  def inspect(dict, opts) do
    concat(["#Wasm.Engine<", to_doc(dict.reference, opts), ">"])
  end
end

defmodule Worker.Adapters.Runtime.Wasm.Engine.Cache do
  use GenServer, restart: :permanent

  require Logger

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: :wasmtime_engine_cache)
  end

  @impl true
  def init(_args) do
    table = :ets.new(:wasm_engine, [:set, :named_table, :protected])
    Logger.info("Wasm Engine Cache: started")
    {:ok, table}
  end

  @impl true
  def handle_call({:insert, engine}, _from, table) do
    :ets.insert(table, {"wamtime_engine", engine})
    Logger.info("Wasm Engine Cache: added engine handle")
    {:reply, :ok, table}
  end
end

defmodule Worker.Adapters.Runtime.Wasm.Module do
  @moduledoc """
  A compiled WebAssembly module.
  A WebAssembly Module contains stateless WebAssembly code that has already been compiled and can be instantiated multiple times.
      # Read a WASM file and compile it into a WASM module
      {:ok, bytes } = File.read("code.wasm")
      {:ok, module} = Wasm.Module.compile(bytes)
  """
  alias Worker.Adapters.Runtime.Wasm

  @type t :: %__MODULE__{
          resource: binary(),
          reference: reference()
        }

  defstruct resource: nil,
            # The actual NIF module resource.
            # Normally the compiler will happily do stuff like inlining the
            # resource in attributes. This will convert the resource into an
            # empty binary with no warning. This will make that harder to
            # accidentally do.
            reference: nil

  @doc """
  Compiles a WASM module from it's WASM (usually a .wasm file) representation.
  """
  @spec compile(Wasm.Engine.t(), binary()) :: {:ok, __MODULE__.t()} | {:error, any()}
  def compile(%Wasm.Engine{resource: engine_resource}, code) when is_binary(code) do
    case Wasm.Nif.compile_module(engine_resource, code) do
      {:ok, resource} -> {:ok, wrap_resource(resource)}
      {:error, err} -> {:error, err}
    end
  end

  defp wrap_resource(resource) do
    %__MODULE__{
      resource: resource,
      reference: make_ref()
    }
  end
end

defimpl Inspect, for: Worker.Adapters.Runtime.Wasm.Module do
  import Inspect.Algebra

  def inspect(dict, opts) do
    concat(["#Wasm.Module<", to_doc(dict.reference, opts), ">"])
  end
end

defmodule Worker.Adapters.Runtime.Wasm.Module.Cache do
  @moduledoc """
    The cache of compiled modules. Implements a GenServer having exclusive writing rights on an underlying ETS table.
  """
  use GenServer, restart: :permanent
  require Logger
  alias Worker.Adapters.Runtime.Wasm.Module

  @cache_server :wasmtime_module_cache_server
  @ets_table :wasmtime_module_cache

  @spec get(String.t(), String.t()) :: Module.t() | :not_found
  def get(function_name, namespace) do
    case :ets.lookup(@ets_table, {function_name, namespace}) do
      [{{^function_name, ^namespace}, module}] -> module
      _ -> :not_found
    end
  end

  @spec insert(String.t(), String.t(), Module.t()) :: :ok
  def insert(function_name, namespace, module) do
    GenServer.call(@cache_server, {:insert, function_name, namespace, module})
  end

  @spec delete(String.t(), String.t()) :: :ok
  def delete(function_name, namespace) do
    GenServer.call(@cache_server, {:delete, function_name, namespace})
  end

  # GenServer callbacks
  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: @cache_server)
  end

  @impl true
  def init(_args) do
    table = :ets.new(@ets_table, [:set, :named_table, :protected])
    Logger.info("Module Cache: started")
    {:ok, table}
  end

  @impl true
  def handle_call({:insert, function_name, namespace, module}, _from, table) do
    :ets.insert(table, {{function_name, namespace}, module})
    Logger.info("Module Cache: added module for #{function_name} in namespace #{namespace}")
    {:reply, :ok, table}
  end

  @impl true
  def handle_call({:delete, function_name, namespace}, _from, table) do
    :ets.delete(table, {function_name, namespace})
    Logger.info("Module Cache: deleted module for #{function_name} in namespace #{namespace}")
    {:reply, :ok, table}
  end
end

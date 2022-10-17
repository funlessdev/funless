# Copyright 2022 Giuseppe De Palma, Matteo Trentin
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

defmodule Worker.Adapters.Runtime.Wasm.Engine do
  @engine_key :engine_handle_key
  @ets_server :wasmtime_engine_server
  @ets_table :wasmtime_engine_cache

  defstruct [
    # The actual NIF Resource.
    resource: nil,
    # Normally the compiler will happily do stuff like inlining the
    # resource in attributes. This will convert the resource into an
    # empty binary with no warning. This will make that harder to
    # accidentaly do.
    reference: nil
  ]

  @type t :: %__MODULE__{
          resource: binary(),
          reference: reference()
        }

  def wrap_resource(resource) do
    %__MODULE__{
      resource: resource,
      reference: make_ref()
    }
  end

  @doc """
  Retrieves the handle to of the Wasmtime Engine.
  It performs a lazy initialization of the engine, if not found in the cache it is creates a new one and stores it.
  """
  @spec get_handle() :: __MODULE__.t()
  def get_handle() do
    case :ets.lookup(@ets_table, @engine_key) do
      [{_, handle}] -> handle
      _ -> start_engine()
    end
  end

  @spec start_engine() :: __MODULE__.t()
  defp start_engine() do
    {:ok, resource} = Worker.Adapters.Runtime.Wasm.Nif.init()
    engine = wrap_resource(resource)
    GenServer.call(@ets_server, {:insert, @engine_key, engine})
    engine
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
    GenServer.start_link(__MODULE__, args, name: :wasmtime_engine_server)
  end

  @impl true
  def init(_args) do
    table = :ets.new(:wasmtime_engine_cache, [:set, :named_table, :protected])
    Logger.info("Wasm Engine Cache: started")
    {:ok, table}
  end

  @impl true
  def handle_call({:insert, key, engine}, _from, table) do
    :ets.insert(table, {key, engine})
    Logger.info("Wasm Engine Cache: engine handle added with key #{key}")
    {:reply, :ok, table}
  end

  @impl true
  def handle_call({:delete, key}, _from, table) do
    :ets.delete(table, key)
    Logger.info("Wasm Engine Cache: engine handle deleted")
    {:reply, :ok, table}
  end
end

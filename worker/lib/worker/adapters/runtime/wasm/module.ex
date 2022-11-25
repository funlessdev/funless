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

defmodule Worker.Adapters.Runtime.Wasm.Module do
  @moduledoc """
  A compiled WebAssembly module.
  A WebAssembly Module contains stateless WebAssembly code that has already been compiled and can be instantiated multiple times.
      # Read a WASM file and compile it into a WASM module
      {:ok, bytes } = File.read("code.wasm")
      {:ok, module} = Wasm.Module.compile(bytes)
  """
  alias Worker.Adapters.Runtime.Wasm
  require Logger

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
    Wasm.Nif.compile_module(engine_resource, code)

    receive do
      {:ok, resource} ->
        Logger.info("Wasm module compiled successfully #{inspect(resource)}")
        {:ok, wrap_resource(resource)}

      {:error, err} ->
        Logger.warn("Wasm module compilation failed: #{inspect(err)}")
        {:error, err}
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

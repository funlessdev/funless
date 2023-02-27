# Copyright 2023 Giuseppe De Palma, Matteo Trentin
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

defmodule Worker.Adapters.Runtime.Wasm.Imports do
  @moduledoc """
  Module containing the WASM imports for FunLess functions.

  The imports are functions that are called by the WASM code. They get the WASM context as first
  argument, which contains the memory and the caller.
  """
  require Logger

  def fl_imports(input_payload, agent) do
    %{
      "__console_log" =>
        {:fn, [:i32, :i32], [],
         fn context, ptr, len -> console_log(:funless, context, ptr, len) end},
      "__get_input_data" =>
        {:fn, [:i32], [],
         fn context, in_ptr -> get_input(:funless, context, in_ptr, input_payload) end},
      "__insert_response" =>
        {:fn, [:i32, :i32], [],
         fn context, ptr, len -> insert_response(:funless, context, agent, ptr, len) end},
      "__insert_error" =>
        {:fn, [:i32, :i32], [],
         fn context, ptr, len -> insert_error(:funless, context, agent, ptr, len) end}
    }
  end

  defp console_log(_api_type, context, ptr, len) do
    text = Wasmex.Memory.read_string(context.caller, context.memory, ptr, len)

    if String.length(text) > 0 do
      Logger.debug("Console log from WASM function: #{text}")
    end

    nil
  end

  defp get_input(_api_type, context, in_ptr, payload) do
    memory = context.memory
    caller = context.caller
    Wasmex.Memory.write_binary(caller, memory, in_ptr, payload)
    nil
  end

  # Load the guest response indicated by the location and length into the :response state field.
  defp insert_response(_api_type, context, agent, ptr, len) do
    caller = context.caller
    memory = context.memory
    r = Wasmex.Memory.read_string(caller, memory, ptr, len)
    Agent.update(agent, fn state -> %{state | response: r} end)
    nil
  end

  # Load the error indicated by the location and length into the :error field
  defp insert_error(_api_type, context, agent, ptr, len) do
    memory = context.memory
    caller = context.caller
    e = Wasmex.Memory.read_string(caller, memory, ptr, len)
    Agent.update(agent, fn state -> %{state | error: e} end)
    nil
  end
end

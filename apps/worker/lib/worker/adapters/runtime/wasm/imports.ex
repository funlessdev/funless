defmodule Worker.Adapters.Runtime.Wasm.Imports do
  @moduledoc false
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

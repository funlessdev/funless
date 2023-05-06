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
         fn context, ptr, len -> insert_error(:funless, context, agent, ptr, len) end},
      "__http_request" =>
        {:fn, [:i32, :i32, :i32, :i32, :i32, :i32, :i32, :i32, :i32, :i32], [],
         fn context,
            response_ptr,
            response_len_ptr,
            status_ptr,
            method,
            uri_ptr,
            uri_len,
            header_ptr,
            header_len,
            body_ptr,
            body_len ->
           http_request(
             :funless,
             context,
             %{
               output: %{response: {response_ptr, response_len_ptr}, status: status_ptr},
               input: %{
                 method: method,
                 uri: {uri_ptr, uri_len},
                 header: {header_ptr, header_len},
                 body: {body_ptr, body_len}
               }
             }
           )
         end}
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

  defp http_request(
         _api_type,
         context,
         %{
           output: %{response: {response_ptr, response_len_ptr}, status: status_ptr},
           input: %{
             method: method,
             uri: {uri_ptr, uri_len},
             header: {header_ptr, header_len},
             body: {body_ptr, body_len}
           }
         }
       ) do
    caller = context.caller
    memory = context.memory

    poison_method =
      case method do
        0 -> :get
        1 -> :post
        2 -> :put
        3 -> :delete
      end

    uri = Wasmex.Memory.read_string(caller, memory, uri_ptr, uri_len)
    headers = Wasmex.Memory.read_string(caller, memory, header_ptr, header_len)

    # headers are encoded client-side as a single string, with "\n" separators between couples
    # and ":" separators between key and value, e.g.
    # Content-Type:application/json\nAge:12345
    poison_headers =
      headers
      |> String.split("\n")
      |> Enum.map(fn s -> s |> String.split(":") |> List.to_tuple() end)

    body = Wasmex.Memory.read_string(caller, memory, body_ptr, body_len)

    Logger.debug("WASM sending HTTP request: #{poison_method} #{uri}")

    request = %HTTPoison.Request{
      method: poison_method,
      url: uri,
      body: body,
      headers: poison_headers
    }

    case HTTPoison.request(request) do
      {:ok, %{status_code: status_code, body: response_body}} ->
        # write status to memory
        Wasmex.Memory.write_binary(
          caller,
          memory,
          status_ptr,
          <<status_code::integer-unsigned-size(16)-little>>
        )

        # write body length to memory
        Wasmex.Memory.write_binary(
          caller,
          memory,
          response_len_ptr,
          <<String.length(response_body)::integer-unsigned-size(32)-little>>
        )

        # write body to memory
        Wasmex.Memory.write_binary(caller, memory, response_ptr, response_body)

        nil

      {:error, err} ->
        # in case of an unexpected error, the status is 0 and the body is empty

        Wasmex.Memory.write_binary(
          caller,
          memory,
          status_ptr,
          <<0::integer-unsigned-size(16)-little>>
        )

        Wasmex.Memory.write_binary(
          caller,
          memory,
          response_len_ptr,
          <<String.length("")::integer-unsigned-size(32)-little>>
        )

        Wasmex.Memory.write_binary(caller, memory, response_ptr, "")

        Logger.error("Error in HTTP request from WASM function #{err}")
        nil
    end
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

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
  alias Data.FunctionMetadata
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
         } = params
       ) do
    caller = context.caller
    memory = context.memory

    if method == -1 or uri_len == -1 do
      http_svc_request(context, params)
    else
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
  end

  defp http_svc_request(
         %{
           caller: caller,
           memory: memory,
           metadata: %FunctionMetadata{} = metadata,
           last_ptr: last_ptr
         },
         %{
           output: %{response: {response_ptr, _}},
           input: %{
             uri: {svc_idx, _},
             body: {body_ptr, _}
           }
         }
       ) do
    {poison_method, uri, req_params, resp_params} = metadata.miniSL_services |> Enum.at(svc_idx)

    poison_headers = [{"Content-Type", "application/json"}]

    # body = Wasmex.Memory.read_string(caller, memory, body_ptr, body_len)
    body = parse_svc_body(caller, memory, body_ptr, req_params, []) |> Enum.into(%{})
    Logger.debug("WASM sending HTTP request from service #{svc_idx}: #{poison_method} #{uri}")

    request = %HTTPoison.Request{
      method: poison_method,
      url: uri,
      body: Jason.encode!(body),
      headers: poison_headers
    }

    case HTTPoison.request(request) do
      {:ok, %{status_code: _status_code, body: response_body}} ->
        # write body to memory
        write_svc_response(caller, memory, last_ptr, response_ptr, response_body, resp_params)
        Wasmex.Memory.write_binary(caller, memory, response_ptr, response_body)
        nil

      {:error, err} ->
        Wasmex.Memory.write_binary(caller, memory, response_ptr, <<0>>)

        Logger.error("Error in HTTP request from WASM function #{inspect(err)}")
        nil
    end
  end

  defp parse_svc_body(_, _, _, [], result) do
    result
  end

  defp parse_svc_body(caller, memory, body_ptr, [{param_name, param_type} | rest], result) do
    {value, offset} =
      case param_type do
        :bool ->
          <<x::size(32)-little>> = Wasmex.Memory.read_binary(caller, memory, body_ptr, 4)
          {x, 4}

        :int ->
          <<x::size(32)-little>> = Wasmex.Memory.read_binary(caller, memory, body_ptr, 4)
          {x, 4}

        :float ->
          <<x::float-size(64)-little>> = Wasmex.Memory.read_binary(caller, memory, body_ptr, 8)
          {x, 8}

        :string ->
          <<ptr::size(32)-little>> = Wasmex.Memory.read_binary(caller, memory, body_ptr, 4)
          <<len::size(32)-little>> = Wasmex.Memory.read_binary(caller, memory, body_ptr + 4, 4)
          str = Wasmex.Memory.read_string(caller, memory, ptr, len)
          {str, 8}

        :array ->
          <<ptr::size(32)-little>> = Wasmex.Memory.read_binary(caller, memory, body_ptr, 4)
          <<len::size(32)-little>> = Wasmex.Memory.read_binary(caller, memory, body_ptr + 4, 4)
          bin_arr = Wasmex.Memory.read_string(caller, memory, ptr, len)
          arr = for <<x::size(32)-little <- bin_arr>>, do: x
          {arr, 8}
      end

    parse_svc_body(caller, memory, body_ptr + offset, rest, [{param_name, value} | result])
  end

  defp write_svc_response(_, _, _, _, _, []) do
    nil
  end

  defp write_svc_response(caller, memory, last_ptr, response_ptr, response_body, [
         {param_name, param_type} | rest
       ]) do
    val = Jason.decode!(response_body)[param_name]

    {offset, fl_offset} =
      case param_type do
        :bool ->
          bin_val =
            if val do
              1
            else
              0
            end

          Wasmex.Memory.write_binary(caller, memory, response_ptr, <<bin_val::size(32)-little>>)
          {4, 0}

        :int ->
          Wasmex.Memory.write_binary(caller, memory, response_ptr, <<val::size(32)-little>>)
          {4, 0}

        :float ->
          Wasmex.Memory.write_binary(caller, memory, response_ptr, <<val::float-size(64)-little>>)
          {8, 0}

        :string ->
          len = byte_size(val)
          Wasmex.Memory.write_binary(caller, memory, last_ptr, val)
          Wasmex.Memory.write_binary(caller, memory, response_ptr, <<last_ptr::size(32)-little>>)
          Wasmex.Memory.write_binary(caller, memory, response_ptr + 4, <<len::size(32)-little>>)
          {8, len}

        :array ->
          arr = val |> Enum.into(<<>>, fn x -> <<x::size(32)-little>> end)
          len = byte_size(arr)
          Wasmex.Memory.write_binary(caller, memory, last_ptr, arr)
          Wasmex.Memory.write_binary(caller, memory, response_ptr, <<last_ptr::size(32)-little>>)
          Wasmex.Memory.write_binary(caller, memory, response_ptr + 4, <<len::size(32)-little>>)
          {8, len}
      end

    write_svc_response(
      caller,
      memory,
      last_ptr + fl_offset,
      response_ptr + offset,
      response_body,
      rest
    )
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

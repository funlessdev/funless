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

defmodule Worker.Adapters.Runtime.Wasm.Runner do
  @moduledoc """
  Adapter to invoke WebAssembly functions.

  The Runner is responsible for:
  - deserializing the input Wasm module
  - preparing a store for the module
  - instantiating the module with imports functions
  - invoking the exported function `__invoke` on the Wasm module
  - Retrieving the result from the Wasm module

  It makes use of an Agent to store the result of the execution of a function,
  so it can be retrieved after the invocation is done.

  This is needed because the result is taken from the Wasm module
  right before the wasm instance is done executing, via one of the two imported functions
  `__insert_response` and `__insert_error`.

  The flow is:
  - call the exported function `__invoke` in the wasm module
  - the wasm instance does its execution, in particular the user-defined 'fl_main' function
  - the wasm instance takes the result of fl_main and calls either `__insert_response` or `__insert_error` to store the result in the Agent
  - the Runner retrieves the result from the Agent and returns it to the caller
  """
  @behaviour Worker.Domain.Ports.Runtime.Runner

  # @runtime_version "__runtime_version"
  @wasm_invoke "__invoke"
  @exec_timeout 60_000

  alias Data.ExecutionResource
  alias Data.FunctionMetadata
  alias Data.FunctionStruct
  alias Worker.Adapters.Runtime.Wasm.Engine
  alias Worker.Adapters.Runtime.Wasm.Imports

  alias Wasmex.Wasi.WasiOptions

  require Logger

  @impl true
  def run_function(
        %FunctionStruct{name: name, module: mod, metadata: metadata},
        args,
        %ExecutionResource{
          resource: wasm_module
        }
      ) do
    Logger.debug("Runner: Invoking #{mod}/#{name} with args #{inspect(args)}")

    # Spin up an agent to store the result of the invocation
    {:ok, result_agent} = Agent.start_link(fn -> %{error: nil, response: nil} end)

    res =
      perform_invocation(wasm_module, args, result_agent, metadata)
      |> parse_return(result_agent)

    Logger.debug("Runner: returning result #{inspect(res)}")

    # Stop the agent
    Agent.stop(result_agent)
    res
  end

  defp perform_invocation(wasm_module, input_args, agent, %FunctionMetadata{} = metadata) do
    parsed_input = Jason.encode!(input_args)

    Logger.debug(
      "Runner: performing invocation with input #{parsed_input}, byte_size #{byte_size(parsed_input)}"
    )

    imports = %{
      "fl_imps" => Imports.fl_imports(parsed_input, agent)
    }

    with {:ok, wasm_mod} <- Wasmex.Module.unsafe_deserialize(wasm_module, Engine.get_handle()),
         {:ok, store} <- Wasmex.Store.new_wasi(%WasiOptions{}, nil, Engine.get_handle()),
         {:ok, instance} <- Wasmex.Instance.new(store, wasm_mod, imports) do
      # invoke @wasm_invoke
      # if it fails, set guest_error, return 1
      # if it succeeeds, set guest_response, return 0
      Logger.debug("Runner: Invoking exported #{@wasm_invoke}")

      if Wasmex.Instance.function_export_exists(store, instance, @wasm_invoke) do
        call_wasm_invoke(store, instance, parsed_input, metadata, imports)
      else
        call_main_func(store, instance, input_args, metadata, imports)
      end
    end
  end

  defp call_wasm_invoke(store, instance, parsed_input, metadata, imports) do
    Wasmex.Instance.call_exported_function(
      store,
      instance,
      @wasm_invoke,
      [
        byte_size(parsed_input)
      ],
      {self(), :from}
    )

    handle_wasm_messages(imports, metadata, 0)
  end

  defp call_main_func(
         store,
         instance,
         input_args,
         %FunctionMetadata{main_func: main_func, params: []} = metadata,
         imports
       )
       when is_list(input_args) do
    {translated_args, last_ptr} =
      input_args
      |> Enum.reduce({[], 0}, fn value, {translated_vals, last_ptr} ->
        {translated_val, new_ptr} = translate_argument(value, store, instance, last_ptr)
        {translated_val ++ translated_vals, new_ptr}
      end)

    translated_args = translated_args |> Enum.reverse()

    Wasmex.Instance.call_exported_function(
      store,
      instance,
      main_func,
      [last_ptr + 65_536 | translated_args],
      {self(), :from}
    )

    handle_wasm_messages(imports, metadata, last_ptr)
  end

  defp call_main_func(
         store,
         instance,
         input_args,
         %FunctionMetadata{main_func: main_func, params: [_ | _] = params_names} = metadata,
         imports
       )
       when is_map(input_args) do
    {translated_args, last_ptr} =
      params_names
      |> Enum.reduce({[], 0}, fn name, {translated_vals, last_ptr} ->
        value = input_args |> Map.get(name)
        {translated_val, new_ptr} = translate_argument(value, store, instance, last_ptr)
        {translated_val ++ translated_vals, new_ptr}
      end)

    translated_args = translated_args |> Enum.reverse()

    Wasmex.Instance.call_exported_function(
      store,
      instance,
      main_func,
      [last_ptr + 65_536 | translated_args],
      {self(), :from}
    )

    handle_wasm_messages(imports, metadata, last_ptr)
  end

  defp translate_argument(value, store, instance, last_ptr) when is_binary(value) do
    {:ok, memory} = Wasmex.Instance.memory(store, instance)
    len = byte_size(value)
    Wasmex.Memory.write_binary(store, memory, last_ptr, value)
    {[len, last_ptr], last_ptr + len}
  end

  defp translate_argument(value, store, instance, last_ptr) when is_list(value) do
    {:ok, memory} = Wasmex.Instance.memory(store, instance)
    bin_value = value |> Enum.into(<<>>, fn x -> <<x::32>> end)
    len = byte_size(bin_value)
    Wasmex.Memory.write_binary(store, memory, last_ptr, bin_value)
    {[len, last_ptr], last_ptr + len}
  end

  defp translate_argument(value, _store, _instance, last_ptr) when is_boolean(value) do
    if value == true do
      {[1], last_ptr}
    else
      {[0], last_ptr}
    end
  end

  defp translate_argument(value, _store, _instance, last_ptr)
       when is_integer(value) or is_float(value) do
    {[value], last_ptr}
  end

  # NOTE: last_ptr is a temporary solution to handle the miniSL case of string responses.
  # miniSL gives us the pointer to the response (which will hold str_ptr and str_len), but no
  # information as to where the string itself is allocated. We use last_ptr to have an idea
  # of where we can allocate (between last_ptr and the first miniSL allocation we have 64K of free memory).
  # This will be very likely changed in the future, or limited to the specific miniSL case to avoid confusion
  # in the code.
  defp handle_wasm_messages(imports, %FunctionMetadata{} = metadata, last_ptr) do
    receive do
      {:returned_function_call, {:ok, result}, _} ->
        Logger.debug("Wasm: Function returned successfully: #{inspect(result)}")
        {:ok, result}

      {:invoke_callback, namespace_name, import_name, context, params, token} ->
        Logger.debug("Runner: requested invocation of import #{namespace_name}: #{import_name}")

        invoke_import_fn(
          namespace_name,
          import_name,
          context |> Map.put(:last_ptr, last_ptr),
          params,
          metadata,
          token,
          imports
        )

        handle_wasm_messages(imports, metadata, last_ptr)

      value ->
        Logger.error("Runner: WebAssembly runtime failed to run function: #{inspect(value)}")
        {:error, "WebAssembly runtime failed to run function: #{inspect(value)}"}
    after
      @exec_timeout -> {:error, "function timed out"}
    end
  end

  defp invoke_import_fn(
         namespace_name,
         import_name,
         context,
         params,
         %FunctionMetadata{} = metadata,
         token,
         imports
       ) do
    context =
      Map.merge(
        context,
        %{
          memory: Wasmex.Memory.__wrap_resource__(Map.get(context, :memory)),
          caller: Wasmex.StoreOrCaller.__wrap_resource__(Map.get(context, :caller)),
          metadata: metadata
        }
      )

    {success, return_value} =
      try do
        {:fn, _params, _returns, callback} =
          imports
          |> Map.get(namespace_name, %{})
          |> Map.get(import_name)

        # either use special case for HTTP request, or change context to include function metadata
        {true, apply(callback, [context | params])}
      rescue
        e in RuntimeError -> {false, e.message}
      end

    return_values =
      case return_value do
        nil -> []
        _ -> [return_value]
      end

    :ok = Wasmex.Native.instance_receive_callback_result(token, success, return_values)
  end

  defp parse_return({:ok, [0]}, agent) do
    Logger.debug("Runner: invoke returned status success.")

    # get response from agent
    Agent.get(agent, fn state ->
      {:ok, Jason.decode!(state.response)}
    end)
  end

  defp parse_return({:ok, [1]}, agent) do
    Logger.debug("Runner: invoke returned status error.")
    # get error from agent
    Agent.get(agent, fn state ->
      {:error, {:exec_error, state.error}}
    end)
  end

  defp parse_return({:error, err}, _agent) do
    Logger.debug("Runner: error during invocation: #{inspect(err)}")
    {:error, :failed}
  end
end

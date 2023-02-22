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

defmodule Integration.FnWasmTest do
  use ExUnit.Case

  alias Worker.Adapters.Runtime.Wasm

  @engine_key :engine_handle_key
  @engine_cache_server :wasmtime_engine_server
  @ets_engine_table :wasmtime_engine_cache

  setup_all do
    code = File.read!("test/fixtures/code.wasm")

    %{code: code}
  end

  describe "Wasmtime Runtime" do
    setup do
      Worker.Provisioner.Mock |> Mox.stub_with(Worker.Adapters.Runtime.Wasm.Provisioner)
      :ok
    end

    test "get_handle should retrieve the handle when it is stored" do
      handle = "test-handle"
      GenServer.call(@engine_cache_server, {:insert, @engine_key, handle})
      assert :ets.lookup(@ets_engine_table, @engine_key) == [{@engine_key, handle}]

      assert Wasm.Engine.get_handle() == handle
      GenServer.call(@engine_cache_server, {:delete, @engine_key})
    end

    test "get_handle should create and return a new engine handle when not found in the cache" do
      assert :ets.lookup(@ets_engine_table, @engine_key) == []
      handle = Wasm.Engine.get_handle()

      assert :ets.lookup(@ets_engine_table, @engine_key) == [{@engine_key, handle}]
      GenServer.call(@engine_cache_server, {:delete, @engine_key})
    end

    test "get_handle should not overwrite handle after first invocation" do
      handle = Wasm.Engine.get_handle()
      assert :ets.lookup(@ets_engine_table, @engine_key) == [{@engine_key, handle}]
      handle2 = Wasm.Engine.get_handle()
      assert :ets.lookup(@ets_engine_table, @engine_key) == [{@engine_key, handle2}]
      assert handle == handle2
      GenServer.call(@engine_cache_server, {:delete, @engine_key})
    end
  end

  describe "Wasmtime Runtime Provisioner" do
    test "compile actually works with a sample code.wasm", %{code: code} do
      engine = Wasm.Engine.get_handle()
      assert {:ok, %Wasm.Module{resource: _}} = Wasm.Module.compile(engine, code)
      GenServer.call(@engine_cache_server, {:delete, @engine_key})
    end
  end
end

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

defmodule Integration.FnWasmTest do
  use ExUnit.Case

  alias Worker.Adapters.Runtime.Wasm.Engine
  alias Worker.Adapters.Runtime.Wasm.Module
  alias Worker.Adapters.Runtime.Wasm.Provisioner
  alias Worker.Domain.FunctionStruct
  alias Worker.Domain.ExecutionResource

  @engine_key :engine_handle_key
  @engine_cache_server :wasmtime_engine_server
  @ets_engine_table :wasmtime_engine_cache

  @module_cache_server :wasmtime_module_cache_server
  @ets_module_table :wasmtime_module_cache

  setup_all do
    code = File.read!("test/fixtures/code.wasm")

    %{code: code}
  end

  describe "Wasmtime Runtime Engine" do
    setup do
      Worker.Provisioner.Mock |> Mox.stub_with(Worker.Adapters.Runtime.Wasm.Provisioner)
      :ok
    end

    test "get_handle should retrieve the handle when it is stored" do
      handle = "test-handle"
      GenServer.call(@engine_cache_server, {:insert, @engine_key, handle})
      assert :ets.lookup(@ets_engine_table, @engine_key) == [{@engine_key, handle}]

      assert Engine.get_handle() == handle
      GenServer.call(@engine_cache_server, {:delete, @engine_key})
    end

    test "get_handle should create and return a new engine handle when not found in the cache" do
      assert :ets.lookup(@ets_engine_table, @engine_key) == []
      handle = Engine.get_handle()

      assert :ets.lookup(@ets_engine_table, @engine_key) == [{@engine_key, handle}]
      GenServer.call(@engine_cache_server, {:delete, @engine_key})
    end

    test "get_handle should not overwrite handle after first invocation" do
      handle = Engine.get_handle()
      assert :ets.lookup(@ets_engine_table, @engine_key) == [{@engine_key, handle}]
      handle2 = Engine.get_handle()
      assert :ets.lookup(@ets_engine_table, @engine_key) == [{@engine_key, handle2}]
      assert handle == handle2
      GenServer.call(@engine_cache_server, {:delete, @engine_key})
    end
  end

  describe "Wasmtime Runtime Module" do
    test "compile actually works with a sample code.wasm", %{code: code} do
      engine = Engine.get_handle()
      assert {:ok, %Module{resource: _}} = Module.compile(engine, code)
      GenServer.call(@engine_cache_server, {:delete, @engine_key})
    end

    test "provisioner compiles and caches when not found in cache", %{code: code} do
      fun = %FunctionStruct{code: code, name: "test", namespace: "ns"}

      assert Module.Cache.get(fun.name, fun.namespace) == :not_found

      assert {:ok, %ExecutionResource{resource: mod}} = Provisioner.provision(fun)

      cached_mod = Module.Cache.get(fun.name, fun.namespace)

      assert cached_mod == mod
      assert cached_mod.resource == mod.resource

      GenServer.call(@module_cache_server, {:delete, fun.name, fun.namespace})
    end

    test "provisioner does not compile new module when found in cache" do
      fun = %FunctionStruct{name: "test", namespace: "ns"}
      module = %{resource: "test-resource"}
      key = {fun.name, fun.namespace}
      GenServer.call(@module_cache_server, {:insert, fun.name, fun.namespace, module})

      assert :ets.lookup(@ets_module_table, key) == [{key, module}]

      assert {:ok, %ExecutionResource{resource: res}} = Provisioner.provision(fun)
      assert res == module.resource
      GenServer.call(@module_cache_server, {:delete, fun.name, fun.namespace})
    end
  end
end

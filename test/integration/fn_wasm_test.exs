defmodule Integration.FnWasmTest do
  use ExUnit.Case

  @engine_key :engine_handle_key
  @ets_server :wasmtime_engine_server
  @ets_table :wasmtime_engine_cache

  describe "Wasmtime Runtime Engine" do
    setup do
      Worker.Provisioner.Mock |> Mox.stub_with(Worker.Adapters.Runtime.Wasm.Provisioner)
      :ok
    end

    test "get_handle should create and return a new engine handle when not found in the cache" do
      assert :ets.lookup(@ets_table, @engine_key) == []
      handle = Worker.Adapters.Runtime.Wasm.Engine.get_handle()

      assert :ets.lookup(@ets_table, @engine_key) == [{@engine_key, handle}]
    end

    test "get_handle should retrieve the handle when it is stored" do
      handle = "test-handle"
      GenServer.call(@ets_server, {:insert, @engine_key, handle})
      assert :ets.lookup(@ets_table, @engine_key) == [{@engine_key, handle}]

      assert Worker.Adapters.Runtime.Wasm.Engine.get_handle() == handle
    end

    test "get_handle should not overwrite handle after first invocation" do
      handle = Worker.Adapters.Runtime.Wasm.Engine.get_handle()
      assert :ets.lookup(@ets_table, @engine_key) == [{@engine_key, handle}]
      handle2 = Worker.Adapters.Runtime.Wasm.Engine.get_handle()
      assert :ets.lookup(@ets_table, @engine_key) == [{@engine_key, handle2}]
      assert handle == handle2
    end
  end
end

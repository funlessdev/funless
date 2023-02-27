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

defmodule Integration.Adapters.WasmTest do
  use ExUnit.Case
  import Mox, only: [verify_on_exit!: 1]
  require Logger

  alias Worker.Adapters.Runtime.Wasm.Provisioner
  alias Worker.Adapters.Runtime.Wasm.Runner
  alias Worker.Domain.Ports.ResourceCache

  setup :verify_on_exit!

  describe "Wasmex Provisioner" do
    setup do
      Worker.Provisioner.Mock |> Mox.stub_with(Worker.Adapters.Runtime.Wasm.Provisioner)
      Worker.ResourceCache.Mock |> Mox.stub_with(Worker.Adapters.ResourceCache)

      function = %Data.FunctionStruct{
        name: "test-function",
        module: "test-module",
        code: File.read!("test/fixtures/code.wasm")
      }

      {:ok, function: function}
    end

    test "provision should return {:ok, %ExecutionResource{..}} when no errors occur", %{
      function: function
    } do
      assert {:ok, %{resource: _module}} = Provisioner.provision(function)
    end

    test "provision should return {:error, :code_not_found} when function code is nil", %{
      function: function
    } do
      function = %{function | code: nil}
      assert {:error, :code_not_found} = Provisioner.provision(function)
    end

    test "provision should return {:error, msg} when compiling fails", %{
      function: function
    } do
      function = %{function | code: "bad wasm code"}
      assert {:error, msg} = Provisioner.provision(function)
      assert msg != :code_not_found
    end
  end

  describe "Wasmex Runner" do
  end
end

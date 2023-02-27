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
        code: File.read!("test/fixtures/not_impl.wasm")
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
    setup do
      Worker.Provisioner.Mock |> Mox.stub_with(Worker.Adapters.Runtime.Wasm.Provisioner)
      Worker.ResourceCache.Mock |> Mox.stub_with(Worker.Adapters.ResourceCache)
      Worker.Runner.Mock |> Mox.stub_with(Worker.Adapters.Runtime.Wasm.Runner)

      err_function = %Data.FunctionStruct{
        name: "err_function",
        module: "testmodule",
        code: File.read!("test/fixtures/not_impl.wasm")
      }

      hello_function = %Data.FunctionStruct{
        name: "hello_function",
        module: "testmodule",
        code: File.read!("test/fixtures/hello_name.wasm")
      }

      {:ok, err_function: err_function, hello_function: hello_function}
    end

    test "invalid input" do
      function = %{name: "f", module: "m"}
      args = %{}

      resource = %Data.ExecutionResource{
        resource: "this is not webassembly"
      }

      assert {:error, :failed} = Runner.run_function(function, args, resource)
    end

    test "run should return {:error, {:exec_error, msg}} when error occurs while execution", %{
      err_function: err_function
    } do
      # Provisione the function
      assert {:ok, %{resource: _module} = resource} = Provisioner.provision(err_function)

      # Run the function
      assert {:error, {:exec_error, _}} = Runner.run_function(err_function, %{}, resource)
    end

    test "run should return {:ok, result} when no errors occur", %{
      hello_function: hello_function
    } do
      # Provisione the function
      assert {:ok, %{resource: _module} = resource} = Provisioner.provision(hello_function)

      # Run the function
      assert {:ok, result} =
               Runner.run_function(hello_function, %{"name" => "Team FunLess"}, resource)

      assert result == %{"payload" => "Hello Team FunLess!"}
    end
  end
end

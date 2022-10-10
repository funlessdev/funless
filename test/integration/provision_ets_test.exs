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

defmodule Integration.ProvisionEtsTest do
  use ExUnit.Case

  alias Worker.Adapters.RuntimeCache.ETS
  alias Worker.Domain.ProvisionRuntime
  alias Worker.Domain.RuntimeStruct

  import Mox, only: [verify_on_exit!: 1]

  setup :verify_on_exit!

  setup_all do
    function = %{
      name: "hellojs",
      namespace: "_",
      image: "nodejs",
      code: "console.log(\"hello\")"
    }

    %{function: function}
  end

  describe "Provisioning requests and ETS RuntimeCache" do
    setup do
      Worker.Provisioner.Mock |> Mox.stub_with(Worker.Adapters.Runtime.Provisioner.Test)
      Worker.RuntimeCache.Mock |> Mox.stub_with(Worker.Adapters.RuntimeCache.ETS)

      Worker.Provisioner.Mock
      |> Mox.stub(:prepare, fn _function, _runtime ->
        {:ok,
         %RuntimeStruct{
           host: "127.0.0.1",
           port: "8080",
           name: "test-runtime"
         }}
      end)

      :ok
    end

    test "prepare_runtime should insert runtime in storage when successfull", %{
      function: function
    } do
      assert ETS.get(function.name, function.namespace) == :runtime_not_found

      {atom, runtime} = ProvisionRuntime.prepare_runtime(function)
      assert atom == :ok

      assert ETS.get(function.name, function.namespace) == runtime

      ETS.delete(function.name, function.namespace)
    end

    test "multiple prepare_runtime should overwrite runtime in cache", %{
      function: function
    } do
      assert ETS.get(function.name, function.namespace) == :runtime_not_found

      assert {:ok, runtime1} = ProvisionRuntime.prepare_runtime(function)

      assert ETS.get(function.name, function.namespace) == runtime1

      Worker.Provisioner.Mock
      |> Mox.stub(:prepare, fn _function, _runtime ->
        {:ok,
         %RuntimeStruct{
           host: "127.0.0.1",
           port: "8080",
           name: "test-runtime-2"
         }}
      end)

      assert {:ok, runtime2} = ProvisionRuntime.prepare_runtime(function)

      assert ETS.get(function.name, function.namespace) == runtime2

      ETS.delete(function.name, function.namespace)
    end

    test "prepare_runtime should return error when provisioner fails", %{
      function: function
    } do
      Worker.Provisioner.Mock
      |> Mox.stub(:prepare, fn _function, _runtime ->
        {:error, "error"}
      end)

      assert {:error, _} = ProvisionRuntime.prepare_runtime(function)

      assert ETS.get(function.name, function.namespace) == :runtime_not_found
    end
  end
end

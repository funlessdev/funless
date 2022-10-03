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

  alias Worker.Adapters.RuntimeTracker.ETS
  alias Worker.Domain.ProvisionRuntime
  alias Worker.Domain.RuntimeStruct

  import Mox, only: [verify_on_exit!: 1]

  setup :verify_on_exit!

  describe "Provisioning requests and ETS RuntimeTracker" do
    setup do
      Worker.Provisioner.Mock |> Mox.stub_with(Worker.Adapters.Runtime.Provisioner.Test)
      Worker.RuntimeTracker.Mock |> Mox.stub_with(Worker.Adapters.RuntimeTracker.ETS)

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

    test "prepare_runtime should insert runtime in storage when successfull" do
      function = %{name: "fn", namespace: "_", image: "", code: ""}

      assert ETS.get_runtimes("fn") == []

      {atom, runtime} = ProvisionRuntime.prepare_runtime(function)
      assert atom == :ok

      assert ETS.get_runtimes("fn") == [runtime]

      ETS.delete_runtime("fn", runtime)
    end

    test "multiple prepare_runtime should insert multiple runtimes in storage" do
      function = %{name: "test-fn", namespace: "_", image: "", code: ""}

      assert ETS.get_runtimes("test-fn") == []

      {atom, runtime1} = ProvisionRuntime.prepare_runtime(function)
      assert atom == :ok

      assert ETS.get_runtimes("test-fn") == [runtime1]

      Worker.Provisioner.Mock
      |> Mox.stub(:prepare, fn _function, _runtime ->
        {:ok,
         %RuntimeStruct{
           host: "127.0.0.1",
           port: "8080",
           name: "test-runtime-2"
         }}
      end)

      {atom, runtime2} = ProvisionRuntime.prepare_runtime(function)
      assert atom == :ok

      assert ETS.get_runtimes("test-fn") == [runtime1, runtime2]

      ETS.delete_runtime("test-fn", runtime1)
      ETS.delete_runtime("test-fn", runtime2)
    end

    test "prepare_runtime should return error when provisioner fails" do
      function = %{name: "test-fail", namespace: "_", image: "", code: ""}

      Worker.Provisioner.Mock
      |> Mox.stub(:prepare, fn _function, _runtime ->
        {:error, "error"}
      end)

      {atom, _runtime} = ProvisionRuntime.prepare_runtime(function)
      assert atom == :error

      assert ETS.get_runtimes("test-fail") == []
    end
  end
end

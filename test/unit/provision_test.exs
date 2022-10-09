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

defmodule ProvisionTest do
  use ExUnit.Case, async: true

  alias Worker.Domain.ProvisionRuntime
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

  describe "Provisioning requests" do
    setup do
      Worker.Provisioner.Mock |> Mox.stub_with(Worker.Adapters.Runtime.Provisioner.Test)
      Worker.RuntimeCache.Mock |> Mox.stub_with(Worker.Adapters.RuntimeCache.Test)
      :ok
    end

    test "prepare_runtime should return {:error, err} when the underlying functions encounter errors",
         %{function: function} do
      Worker.Provisioner.Mock
      |> Mox.stub(
        :prepare,
        fn _function, _runtime -> {:error, "generic error"} end
      )

      assert ProvisionRuntime.prepare_runtime(function) == {:error, "generic error"}
    end

    test "prepare_runtime should not call the function storage when successfull runtime creation",
         %{function: function} do
      Worker.Provisioner.Mock
      |> Mox.stub(:prepare, fn _function, _runtime ->
        {:error, "error"}
      end)

      Worker.RuntimeCache.Mock
      |> Mox.expect(:insert_runtime, 0, &Worker.Adapters.RuntimeCache.Test.insert_runtime/2)

      assert ProvisionRuntime.prepare_runtime(function) == {:error, "error"}
    end

    test "prepare_runtime should call the storage when sucessfull runtime creation",
         %{function: function} do
      Worker.RuntimeCache.Mock
      |> Mox.expect(:insert_runtime, 1, &Worker.Adapters.RuntimeCache.Test.insert_runtime/2)

      rt_from_test = %Worker.Domain.RuntimeStruct{
        host: "localhost",
        name: "test-runtime",
        port: "8080"
      }

      assert ProvisionRuntime.prepare_runtime(function) ==
               {:ok, rt_from_test}
    end

    test "prepare_runtime should return storage error when storing fails",
         %{function: function} do
      Worker.RuntimeCache.Mock
      |> Mox.stub(:insert_runtime, fn _function, _runtime ->
        {:error, "insert error"}
      end)

      assert ProvisionRuntime.prepare_runtime(function) == {:error, "insert error"}
    end
  end
end

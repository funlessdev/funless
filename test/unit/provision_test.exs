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

  describe "ProvisionRuntime" do
    setup do
      Worker.Provisioner.Mock |> Mox.stub_with(Worker.Adapters.Runtime.Provisioner.Test)
      Worker.RuntimeCache.Mock |> Mox.stub_with(Worker.Adapters.RuntimeCache.Test)
      :ok
    end

    test "should return {:error, err} when the underlying functions encounter errors",
         %{function: function} do
      Worker.Provisioner.Mock
      |> Mox.expect(:provision, fn _function -> {:error, "generic error"} end)

      assert ProvisionRuntime.provision(function) == {:error, "generic error"}
    end

    test "should not call the function storage when successfull runtime creation",
         %{function: function} do
      Worker.Provisioner.Mock
      |> Mox.stub(:provision, fn _function -> {:error, "error"} end)

      Worker.RuntimeCache.Mock
      |> Mox.expect(:insert, 0, &Worker.Adapters.RuntimeCache.Test.insert/3)

      assert ProvisionRuntime.provision(function) == {:error, "error"}
    end

    test "should call the storage when sucessfull runtime creation",
         %{function: function} do
      Worker.RuntimeCache.Mock
      |> Mox.expect(:insert, 1, &Worker.Adapters.RuntimeCache.Test.insert/3)

      rt_from_test = %Worker.Domain.RuntimeStruct{
        host: "localhost",
        name: "test-runtime",
        port: "8080"
      }

      assert ProvisionRuntime.provision(function) ==
               {:ok, rt_from_test}
    end

    test "should return error when caching fails",
         %{function: function} do
      Worker.RuntimeCache.Mock
      |> Mox.expect(:insert, fn _function, _ns, _runtime -> {:error, "insert error"} end)

      assert ProvisionRuntime.provision(function) == {:error, "insert error"}
    end
  end
end

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

  alias Worker.Domain.ExecutionResource
  alias Worker.Domain.ProvisionResource

  alias Worker.Adapters.ResourceCache
  alias Worker.Adapters.Runtime.Provisioner

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
      Worker.Cleaner.Mock |> Mox.stub_with(Worker.Adapters.Runtime.Cleaner.Test)
      Worker.Provisioner.Mock |> Mox.stub_with(Worker.Adapters.Runtime.Provisioner.Test)
      :ok
    end

    test "should return {:error, err} when the underlying provisioner encounter errors",
         %{function: function} do
      Worker.ResourceCache.Mock |> Mox.expect(:get, fn _, _ -> :resource_not_found end)

      Worker.Provisioner.Mock
      |> Mox.expect(:provision, fn _function -> {:error, "generic error"} end)

      assert ProvisionResource.provision(function) == {:error, "generic error"}
    end

    test "should retrieve the resource from the cache when it is already present",
         %{function: function} do
      Worker.ResourceCache.Mock |> Mox.expect(:get, &ResourceCache.Test.get/2)

      # The provisioner should not be called: note the 0
      Worker.Provisioner.Mock |> Mox.expect(:provision, 0, &Provisioner.Test.provision/1)

      # defined in Test adapter
      expected = {:ok, %ExecutionResource{resource: "runtime"}}
      assert ProvisionResource.provision(function) == expected
    end

    test "should call cache insert when new resource is provisioned",
         %{function: function} do
      Worker.ResourceCache.Mock |> Mox.expect(:get, fn _, _ -> :resource_not_found end)
      Worker.ResourceCache.Mock |> Mox.expect(:insert, &ResourceCache.Test.insert/3)

      # defined in Test adapter
      expected = {:ok, %ExecutionResource{resource: "runtime"}}

      assert ProvisionResource.provision(function) == expected
    end

    test "should return error when caching fails",
         %{function: function} do
      Worker.ResourceCache.Mock |> Mox.expect(:get, fn _, _ -> :resource_not_found end)
      Worker.ResourceCache.Mock |> Mox.expect(:insert, fn _, _, _ -> {:error, "insert error"} end)

      assert ProvisionResource.provision(function) == {:error, "insert error"}
    end

    test "should run cleaner when caching fails",
         %{function: function} do
      Worker.ResourceCache.Mock |> Mox.expect(:get, fn _, _ -> :resource_not_found end)
      Worker.ResourceCache.Mock |> Mox.expect(:insert, fn _, _, _ -> {:error, "insert error"} end)

      Worker.Cleaner.Mock |> Mox.expect(:cleanup, fn _ -> :ok end)

      assert ProvisionResource.provision(function) == {:error, "insert error"}
    end
  end
end

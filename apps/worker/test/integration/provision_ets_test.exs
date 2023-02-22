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

defmodule Integration.ProvisionEtsTest do
  use ExUnit.Case

  alias Data.ExecutionResource
  alias Worker.Adapters.ResourceCache
  alias Worker.Domain.ProvisionResource

  import Mox, only: [verify_on_exit!: 1]

  setup :verify_on_exit!

  setup_all do
    function = %{
      name: "hellojs",
      module: "_",
      image: "nodejs",
      code: "console.log(\"hello\")"
    }

    %{function: function}
  end

  describe "Provisioning requests" do
    setup do
      Worker.Provisioner.Mock |> Mox.stub_with(Worker.Adapters.Runtime.Provisioner.Test)
      Worker.ResourceCache.Mock |> Mox.stub_with(Worker.Adapters.ResourceCache)
      :ok
    end

    test "provision should insert resource in cache when successfull", %{
      function: function
    } do
      Worker.Provisioner.Mock
      |> Mox.expect(:provision, fn _ -> {:ok, %ExecutionResource{resource: "a-resource"}} end)

      assert ResourceCache.get(function.name, function.module) == :resource_not_found

      assert {:ok, resource} = ProvisionResource.provision(function)
      assert ResourceCache.get(function.name, function.module) == resource

      ResourceCache.delete(function.name, function.module)
    end

    test "multiple provision return resource in cache", %{
      function: function
    } do
      Worker.Provisioner.Mock
      |> Mox.expect(:provision, fn _ -> {:ok, %ExecutionResource{resource: "a-resource"}} end)

      assert ResourceCache.get(function.name, function.module) == :resource_not_found

      assert {:ok, res1} = ProvisionResource.provision(function)

      assert ResourceCache.get(function.name, function.module) == res1

      Worker.Provisioner.Mock
      |> Mox.expect(:provision, 0, fn _ -> :ignored end)

      assert {:ok, res2} = ProvisionResource.provision(function)
      assert ResourceCache.get(function.name, function.module) == res1
      assert res1 == res2

      ResourceCache.delete(function.name, function.module)
    end

    test "provision should return error when provisioner fails", %{
      function: function
    } do
      Worker.Provisioner.Mock
      |> Mox.expect(:provision, fn _ -> {:error, "error"} end)

      assert {:error, _} = ProvisionResource.provision(function)

      assert ResourceCache.get(function.name, function.module) == :resource_not_found
    end
  end
end

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

defmodule Integration.CleanupEtsTest do
  use ExUnit.Case

  alias Worker.Adapters.ResourceCache
  alias Worker.Domain.CleanupResource
  alias Worker.Domain.ExecutionResource

  import Mox, only: [verify_on_exit!: 1]

  setup :verify_on_exit!

  describe "Cleanup requests" do
    setup do
      Worker.Cleaner.Mock |> Mox.stub_with(Worker.Adapters.Runtime.Cleaner.Test)
      Worker.ResourceCache.Mock |> Mox.stub_with(Worker.Adapters.ResourceCache)
      :ok
    end

    test "cleanup should remove resource from cache when successfull" do
      function = %{name: "fn", namespace: "ns", image: "", code: ""}

      resource = %ExecutionResource{resource: "a-resource"}

      ResourceCache.insert("fn", "ns", resource)
      assert ResourceCache.get("fn", "ns") == resource

      assert CleanupResource.cleanup(function) == :ok
      assert ResourceCache.get("fn", "ns") == :resource_not_found
    end

    test "cleanup should call cleaner passing it the resource from the cache" do
      function = %{name: "fn", namespace: "ns", image: "", code: ""}

      resource = %ExecutionResource{resource: "a-resource"}

      ResourceCache.insert("fn", "ns", resource)
      assert ResourceCache.get("fn", "ns") == resource

      # If we are not passing the resource to the cleaner, this will fail
      # I don't know how to expect a certain parameter to be passed to a function, so this will do
      Worker.Cleaner.Mock |> Mox.expect(:cleanup, 1, fn res -> if res == resource, do: :ok end)

      assert CleanupResource.cleanup(function) == :ok
    end

    test "cleanup should return resource_not_found when not found" do
      function = %{name: "fn", namespace: "ns", image: "", code: ""}

      assert ResourceCache.get("fn", "ns") == :resource_not_found
      assert CleanupResource.cleanup(function) == {:error, :resource_not_found}
    end
  end
end

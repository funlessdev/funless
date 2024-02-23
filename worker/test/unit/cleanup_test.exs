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

defmodule CleanupTest do
  use ExUnit.Case, async: true

  alias Worker.Domain.CleanupResource
  import Mox, only: [verify_on_exit!: 1]

  setup :verify_on_exit!

  setup_all do
    function = %{
      name: "test-cleanup-fn",
      module: "mod",
      code: "code",
      hash: <<0, 0, 0>>
    }

    %{function: function}
  end

  describe "CleanupResource" do
    setup do
      Worker.Cleaner.Mock |> Mox.stub_with(Worker.Adapters.Runtime.Cleaner.Test)
      Worker.ResourceCache.Mock |> Mox.stub_with(Worker.Adapters.ResourceCache.Test)
      Worker.RawResourceStorage.Mock |> Mox.stub_with(Worker.Adapters.RawResourceStorage.Test)
      :ok
    end

    test "cleanup should call cleaner, resource cache delete and raw resource delete when a resource is found for the given function in both storages",
         %{function: function} do
      assert CleanupResource.cleanup(function) == :ok
    end

    test "cleanup should return {:error, :resource_not_found} when no resource is found for the given function in both storages",
         %{function: function} do
      Worker.ResourceCache.Mock |> Mox.expect(:get, fn _, _, _ -> :resource_not_found end)
      Worker.RawResourceStorage.Mock |> Mox.expect(:delete, fn _, _, _ -> {:error, :enoent} end)

      assert CleanupResource.cleanup(function) == {:error, :resource_not_found}
    end

    test "cleanup should return both results when the resource is not found in either storage",
         %{function: function} do
      Worker.ResourceCache.Mock |> Mox.expect(:get, fn _, _, _ -> :resource_not_found end)

      Worker.RawResourceStorage.Mock
      |> Mox.expect(:delete, &Worker.Adapters.RawResourceStorage.Test.delete/3)

      assert CleanupResource.cleanup(function) ==
               {:error, {{:cache, {:error, :resource_not_found}}, {:raw_storage, :ok}}}
    end

    test "cleanup should return error when ResourceCache fails to delete in either storage", %{
      function: function
    } do
      Worker.ResourceCache.Mock |> Mox.expect(:get, fn _, _, _ -> :resource_not_found end)

      Worker.RawResourceStorage.Mock
      |> Mox.expect(:delete, fn _, _, _ -> {:error, "different error"} end)

      assert CleanupResource.cleanup(function) ==
               {:error,
                {{:cache, {:error, :resource_not_found}},
                 {:raw_storage, {:error, "different error"}}}}
    end
  end
end

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

defmodule CleanupTest do
  use ExUnit.Case, async: true

  alias Worker.Domain.CleanupResource
  import Mox, only: [verify_on_exit!: 1]

  setup :verify_on_exit!

  setup_all do
    function = %{
      name: "test-cleanup-fn",
      module: "mod",
      image: "nodejs",
      code: "console.log(\"hello\")"
    }

    %{function: function}
  end

  describe "CleanupResource" do
    setup do
      Worker.Cleaner.Mock |> Mox.stub_with(Worker.Adapters.Runtime.Cleaner.Test)
      Worker.ResourceCache.Mock |> Mox.stub_with(Worker.Adapters.ResourceCache.Test)
      :ok
    end

    test "cleanup should call cleaner and resource cache delete when a resource is found for the given function",
         %{function: function} do
      Worker.Cleaner.Mock |> Mox.expect(:cleanup, &Worker.Adapters.Runtime.Cleaner.Test.cleanup/1)

      Worker.ResourceCache.Mock
      |> Mox.expect(:delete, &Worker.Adapters.ResourceCache.Test.delete/2)

      assert CleanupResource.cleanup(function) == :ok
    end

    test "cleanup should return {:error, :resource_not_found} when no resource is found for the given function",
         %{function: function} do
      Worker.ResourceCache.Mock |> Mox.expect(:get, fn _, _ -> :resource_not_found end)

      assert CleanupResource.cleanup(function) == {:error, :resource_not_found}
    end

    test "cleanup should return error when ResourceCache fails to delete", %{function: function} do
      Worker.ResourceCache.Mock |> Mox.expect(:delete, fn _, _ -> {:error, "error"} end)

      assert CleanupResource.cleanup(function) == {:error, "error"}
    end
  end
end

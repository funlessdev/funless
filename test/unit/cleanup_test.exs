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

  alias Worker.Domain.CleanupRuntime
  import Mox, only: [verify_on_exit!: 1]

  setup :verify_on_exit!

  setup_all do
    function = %{
      name: "test-cleanup-fn",
      namespace: "ns",
      image: "nodejs",
      code: "console.log(\"hello\")"
    }

    %{function: function}
  end

  describe "Cleanup runtime requests" do
    setup do
      Worker.Cleaner.Mock |> Mox.stub_with(Worker.Adapters.Runtime.Cleaner.Test)
      Worker.RuntimeCache.Mock |> Mox.stub_with(Worker.Adapters.RuntimeCache.Test)
      :ok
    end

    test "cleanup should return :ok when a runtime is found and deleted for the given function",
         %{function: function} do
      assert CleanupRuntime.cleanup(function) == :ok
    end

    test "cleanup should return {:error, :runtime_not_found} when no runtime is found for the given function",
         %{function: function} do
      Worker.RuntimeCache.Mock |> Mox.expect(:get, fn _, _ -> :runtime_not_found end)

      assert CleanupRuntime.cleanup(function) == {:error, :runtime_not_found}
    end

    test "cleanup should return error when RuntimeCache fails to delete", %{function: function} do
      Worker.RuntimeCache.Mock
      |> Mox.expect(:delete, fn _, _ -> {:error, "error"} end)

      assert CleanupRuntime.cleanup(function) == {:error, "error"}
    end
  end
end

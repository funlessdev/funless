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

  alias Worker.Adapters.RuntimeCache.ETS
  alias Worker.Domain.CleanupRuntime
  alias Worker.Domain.RuntimeStruct

  import Mox, only: [verify_on_exit!: 1]

  setup :verify_on_exit!

  describe "Cleanup requests and ETS RuntimeCache:" do
    setup do
      Worker.Cleaner.Mock |> Mox.stub_with(Worker.Adapters.Runtime.Cleaner.Test)
      Worker.RuntimeCache.Mock |> Mox.stub_with(Worker.Adapters.RuntimeCache.ETS)
      :ok
    end

    test "cleanup should remove runtime from storage when successfull" do
      function = %{name: "fn", namespace: "ns", image: "", code: ""}

      runtime = %RuntimeStruct{
        host: "127.0.0.1",
        port: "8080",
        name: "test-runtime"
      }

      ETS.insert("fn", "ns", runtime)
      assert ETS.get("fn", "ns") == runtime

      assert CleanupRuntime.cleanup(function) == :ok
      assert ETS.get("fn", "ns") == :runtime_not_found
    end

    test "cleanup should return runtime_not_found when no runtime found" do
      function = %{name: "fn", namespace: "ns", image: "", code: ""}

      assert ETS.get("fn", "ns") == :runtime_not_found
      assert CleanupRuntime.cleanup(function) == {:error, :runtime_not_found}
    end
  end
end

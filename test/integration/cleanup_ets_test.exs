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

  alias Worker.Adapters.RuntimeTracker.ETS
  alias Worker.Domain.CleanupRuntime
  alias Worker.Domain.RuntimeStruct

  import Mox, only: [verify_on_exit!: 1]

  setup :verify_on_exit!

  describe "Cleanup requests and ETS RuntimeTracker" do
    setup do
      Worker.Cleaner.Mock |> Mox.stub_with(Worker.Adapters.Runtime.Cleaner.Test)
      Worker.RuntimeTracker.Mock |> Mox.stub_with(Worker.Adapters.RuntimeTracker.ETS)
      :ok
    end

    test "cleanup should remove runtime from storage when successfull" do
      function = %{name: "fn", namespace: "_", image: "", code: ""}

      runtime = %RuntimeStruct{
        host: "127.0.0.1",
        port: "8080",
        name: "test-runtime"
      }

      ETS.insert_runtime("fn", runtime)
      assert ETS.get_runtimes("fn") == [runtime]

      {atom, res} = CleanupRuntime.cleanup(function)

      assert atom == :ok
      assert res == runtime
      assert ETS.get_runtimes("fn") == []
    end

    test "cleanup should fail when no runtime found" do
      function = %{name: "fn", namespace: "_", image: "", code: ""}

      assert ETS.get_runtimes("fn") == []
      reply = CleanupRuntime.cleanup(function)

      assert reply == {:error, "no runtime found to cleanup"}
    end

    # test cleanup all runtimes

    test "cleanup_all should remove all runtimes from storage when successfull" do
      function = %{name: "fn-test", namespace: "_", image: "", code: ""}

      runtime = %RuntimeStruct{
        host: "127.0.0.1",
        port: "8080",
        name: "test-runtime-1"
      }

      runtime2 = %RuntimeStruct{
        host: "127.0.0.1",
        port: "8080",
        name: "test-runtime-2"
      }

      ETS.insert_runtime("fn-test", runtime)
      ETS.insert_runtime("fn-test", runtime2)
      assert ETS.get_runtimes("fn-test") == [runtime, runtime2]

      {atom, res} = CleanupRuntime.cleanup_all(function)

      assert atom == :ok
      assert res == []
      assert ETS.get_runtimes("fn-test") == []
    end
  end
end

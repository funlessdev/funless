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

defmodule InvokeTest do
  use ExUnit.Case, async: true

  alias Worker.Domain.InvokeFunction
  import Mox, only: [verify_on_exit!: 1]

  setup :verify_on_exit!

  setup_all do
    function = %{
      name: "test-ivk-fn",
      module: "_",
      code: "code",
      hash: <<0, 0, 0>>
    }

    %{function: function}
  end

  describe "InvokeFunction" do
    setup do
      Worker.Runner.Mock |> Mox.stub_with(Worker.Adapters.Runtime.Runner.Test)
      Worker.Provisioner.Mock |> Mox.stub_with(Worker.Adapters.Runtime.Provisioner.Test)
      Worker.RawResourceStorage.Mock |> Mox.stub_with(Worker.Adapters.RawResourceStorage.Test)
      Worker.ResourceCache.Mock |> Mox.stub_with(Worker.Adapters.ResourceCache.Test)
      Worker.WaitForCode.Mock |> Mox.stub_with(Worker.Adapters.WaitForCode.Test)
      :ok
    end

    test "should return {:ok, result map} from the called function when no error is present",
         %{function: function} do
      assert InvokeFunction.invoke(function) == {:ok, %{"result" => "test-output"}}
    end

    test "should return {:error, err} when running the given function raises an error",
         %{function: function} do
      Worker.Runner.Mock |> Mox.expect(:run_function, fn _, _, _ -> {:error, "generic error"} end)

      assert InvokeFunction.invoke(function) == {:error, "generic error"}
    end

    test "should call provision when no resource for execution is found for the given function",
         %{function: function} do
      Worker.ResourceCache.Mock |> Mox.expect(:get, fn _, _, _ -> :resource_not_found end)
      Worker.Provisioner.Mock |> Mox.expect(:provision, fn _ -> {:ok, %{}} end)

      # Output from the test default
      assert InvokeFunction.invoke(function) == {:ok, %{"result" => "test-output"}}
    end

    test "should look for raw resource locally if it isn't found in cache or in the function ",
         %{function: function} do
      function = function |> Map.delete(:code)

      Worker.ResourceCache.Mock |> Mox.expect(:get, 2, fn _, _, _ -> :resource_not_found end)
      Worker.RawResourceStorage.Mock |> Mox.expect(:get, fn _, _, _ -> <<0, 0, 0>> end)

      Worker.Provisioner.Mock
      |> Mox.expect(:provision, 2, fn
        %{code: c} when c != nil -> {:ok, %{}}
        _ -> {:error, :code_not_found}
      end)

      # Output from the test default
      assert InvokeFunction.invoke(function) == {:ok, %{"result" => "test-output"}}
    end

    test "should return {:error, err} when no resource is available and its creation fails",
         %{function: function} do
      Worker.ResourceCache.Mock |> Mox.expect(:get, fn _, _, _ -> :resource_not_found end)

      Worker.Provisioner.Mock |> Mox.expect(:provision, fn _ -> {:error, "creation error"} end)

      assert InvokeFunction.invoke(function) == {:error, "creation error"}
    end

    test "should return {:error, :code_not_found, pid} when the code is not found in cache or raw storage",
         %{
           function: function
         } do
      Worker.ResourceCache.Mock |> Mox.expect(:get, fn _, _, _ -> :resource_not_found end)
      Worker.Provisioner.Mock |> Mox.expect(:provision, fn _ -> {:error, :code_not_found} end)
      Worker.RawResourceStorage.Mock |> Mox.expect(:get, fn _, _, _ -> :resource_not_found end)
      assert {:error, :code_not_found, handler_pid} = InvokeFunction.invoke(function)
      assert is_pid(handler_pid)
    end
  end
end

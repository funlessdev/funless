# Licensed to the Apache Software Foundation (ASF) under one
# or more contributor license agreements.  See the NOTICE file
# distributed with this work for additional information
# regarding copyright ownership.  The ASF licenses this file
# to you under the Apache License, Version 2.0 (the
# "License"); you may not use this file except in compliance
# with the License.  You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing,
# software distributed under the License is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
# KIND, either express or implied.  See the License for the
# specific language governing permissions and limitations
# under the License.
#

defmodule ApiTest.InvokeTest do
  use ExUnit.Case, async: true

  alias Worker.Domain.Api
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

  describe "Worker.Api invoke" do
    setup do
      Worker.Runtime.Mock |> Mox.stub_with(Worker.Adapters.Runtime.Test)
      Worker.RuntimeTracker.Mock |> Mox.stub_with(Worker.Adapters.RuntimeTracker.Test)
      :ok
    end

    test "invoke_function should return {:ok, result map} from the called function when no error is present",
         %{function: function} do
      assert {:ok, %{"result" => "output"}} == Api.Invoke.invoke_function(function)
    end

    test "invoke_function should return {:error, err} when running the given function raises an error",
         %{
           function: function
         } do
      Worker.Runtime.Mock
      |> Mox.stub(:run_function, fn _function, _args, _runtime ->
        {:error, "generic error"}
      end)

      assert {:error, "generic error"} == Api.Invoke.invoke_function(function)
    end

    test "invoke_function should return {:error, err} when no runtime available and its creation fails",
         %{
           function: function
         } do
      Worker.RuntimeTracker.Mock |> Mox.expect(:get_runtimes, fn _ -> [] end)

      Worker.Runtime.Mock
      |> Mox.expect(:prepare, fn _, _ -> {:error, "creation error"} end)

      assert {:error, "creation error"} == Api.Invoke.invoke_function(function)
    end
  end
end

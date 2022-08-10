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

defmodule ApiTest.PrepareTest do
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

  describe "Worker.Api prepare" do
    setup do
      Worker.Runtime.Mock |> Mox.stub_with(Worker.Adapters.Runtime.Test)
      Worker.RuntimeTracker.Mock |> Mox.stub_with(Worker.Adapters.RuntimeTracker.Test)
      :ok
    end

    test "prepare_runtime should return {:error, err} when the underlying functions encounter errors",
         %{function: function} do
      Worker.Runtime.Mock
      |> Mox.stub(:prepare, fn _function, _runtime ->
        {:error, "generic error"}
      end)

      assert Api.Prepare.prepare_runtime(function) == {:error, "generic error"}
    end

    test "prepare_runtime should not call the function storage when the runtime is not created successfully",
         %{function: function} do
      Worker.Runtime.Mock
      |> Mox.stub(:prepare, fn _function, _runtime ->
        {:error, "generic error"}
      end)

      Worker.RuntimeTracker.Mock
      |> Mox.expect(:insert_runtime, 0, &Worker.Adapters.RuntimeTracker.Test.insert_runtime/2)

      assert Api.Prepare.prepare_runtime(function) == {:error, "generic error"}
    end
  end
end

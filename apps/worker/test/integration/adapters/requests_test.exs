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

defmodule RequestTest do
  use ExUnit.Case
  alias Worker.Adapters.Requests.Cluster
  import Mox, only: [verify_on_exit!: 1, set_mox_global: 1]

  setup :set_mox_global
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

  describe "Cluster" do
    setup do
      Worker.Provisioner.Mock |> Mox.stub_with(Worker.Adapters.Runtime.Provisioner.Test)
      Worker.Runner.Mock |> Mox.stub_with(Worker.Adapters.Runtime.Runner.Test)
      Worker.ResourceCache.Mock |> Mox.stub_with(Worker.Adapters.ResourceCache.Test)

      Application.stop(Cluster.Server)
      {:ok, pid} = GenServer.start(Cluster.Server, [])
      %{pid: pid}
    end

    test "invoke call should return {:ok, %{result => ..}} when no errors occur", %{
      pid: pid,
      function: function
    } do
      Worker.ResourceCache.Mock |> Mox.expect(:get, 1, fn _, _ -> :resource_not_found end)

      Worker.Provisioner.Mock
      |> Mox.expect(:provision, &Worker.Adapters.Runtime.Provisioner.Test.provision/1)

      expected = {:ok, %{"result" => "test-output"}}
      assert GenServer.call(pid, {:invoke, function}) == expected
    end

    test "invoke call should retrieve a resource for execution and run the function", %{
      pid: pid,
      function: function
    } do
      Worker.Provisioner.Mock |> Mox.expect(:provision, 0, fn _ -> :ignored end)

      reply = GenServer.call(pid, {:invoke, function})

      assert reply == {:ok, %{"result" => "test-output"}}
    end
  end
end

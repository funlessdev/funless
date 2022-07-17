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

defmodule RequestTest do
  use ExUnit.Case
  alias Worker.Adapters.Requests.Cluster
  import Mox, only: [verify_on_exit!: 1, set_mox_global: 1]

  setup :set_mox_global
  setup :verify_on_exit!

  setup_all do
    function = %Worker.Domain.Function{
      name: "hellojs",
      image: "node:lts-alpine",
      main_file: "/opt/index.js",
      archive: "js/hello.tar.gz"
    }

    %{function: function}
  end

  describe "Cluster" do
    setup do
      Worker.Runtime.Mock |> Mox.stub_with(Worker.Adapters.Runtime.Test)
      Worker.FunctionStorage.Mock |> Mox.stub_with(Worker.Adapters.FunctionStorage.Test)

      Application.stop(Cluster.Server)
      {:ok, pid} = GenServer.start(Cluster.Server, [])
      %{pid: pid}
    end

    test "prepare call should return {:ok, runtime_name} when no errors occur", %{
      pid: pid,
      function: function
    } do
      expected =
        {:ok, %Worker.Domain.Runtime{host: "localhost", name: "hello-runtime", port: "8080"}}

      reply = GenServer.call(pid, {:prepare, function})
      assert expected == reply
    end

    test "prepare call should return {:error, error_message} when an error occurs", %{
      pid: pid,
      function: function
    } do
      expected = %{"error" => "error"}

      Worker.Runtime.Mock
      |> Mox.stub(:prepare, fn _, _ -> {:error, "error"} end)

      reply = GenServer.call(pid, {:prepare, function})
      assert expected == reply
    end

    test "invoke call should return {:ok, %{result => ..}} when no errors occur", %{
      pid: pid,
      function: function
    } do
      expected = {:ok, %{"result" => "output"}}
      reply = GenServer.call(pid, {:invoke, function})
      assert expected == reply
    end

    test "invoke call should prepare a runtime and run the function when no runtime is found", %{
      pid: pid,
      function: function
    } do
      Worker.FunctionStorage.Mock
      |> Mox.expect(:get_runtimes, fn _ -> [] end)

      Worker.Runtime.Mock
      |> Mox.expect(:prepare, fn _, _ ->
        {:ok, %Worker.Domain.Runtime{name: "hello-runtime", host: "localhost", port: "8080"}}
      end)

      reply = GenServer.call(pid, {:invoke, function})

      assert {:ok, %{"result" => "output"}} == reply
    end
  end
end

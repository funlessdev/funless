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

defmodule ApiTest do
  use ExUnit.Case, async: true
  alias Worker.Domain.Api
  import Mox, only: [verify_on_exit!: 1]

  setup :verify_on_exit!

  setup_all do
    function = %{
      name: "hellojs",
      image: "node:lts-alpine",
      main_file: "/opt/index.js",
      archive: "js/hello.tar.gz"
    }

    %{function: function}
  end

  describe "main Worker.Api functions" do
    setup do
      Worker.Containers.Mock
      |> Mox.stub_with(Worker.Adapters.Containers.Test)

      Worker.FunctionStorage.Mock
      |> Mox.stub_with(Worker.Adapters.FunctionStorage.Test)

      :ok
    end

    test "prepare_container should return {:ok, container} when no error is present", %{
      function: function
    } do
      assert {:ok, _} = Api.prepare_container(function)
    end

    test "prepare_container should return {:error, err} when the underlying functions encounter errors",
         %{function: function} do
      Worker.Containers.Mock
      |> Mox.stub(:prepare_container, fn _function, _container ->
        {:error, "generic error"}
      end)

      assert Api.prepare_container(function) == {:error, "generic error"}
    end

    test "prepare_container should not call the function storage when the container is not created successfully",
         %{function: function} do
      Worker.Containers.Mock
      |> Mox.stub(:prepare_container, fn _function, _container ->
        {:error, "generic error"}
      end)

      Worker.FunctionStorage.Mock
      |> Mox.expect(
        :insert_function_container,
        0,
        &Worker.Adapters.FunctionStorage.Test.insert_function_container/2
      )

      assert Api.prepare_container(function) == {:error, "generic error"}
    end

    test "run_function should forward {:ok, results} from the called function when no error is present",
         %{function: function} do
      assert {:ok, "output"} == Api.run_function(function)
    end

    test "run_function should return {:error, {:nocontainer, err}} when no container is found for the given function",
         %{function: function} do
      Worker.FunctionStorage.Mock
      |> Mox.stub(:get_function_containers, fn _function_name ->
        {:error, "generic error"}
      end)

      assert {:error, {:nocontainer, "generic error"}} == Api.run_function(function)
    end

    test "run_function should return {:error, err} when running the given function raises an error",
         %{
           function: function
         } do
      Worker.Containers.Mock
      |> Mox.stub(:run_function, fn _function, _args, _container ->
        {:error, "generic error"}
      end)

      assert {:error, "generic error"} == Api.run_function(function)
    end

    test "cleanup should return {:ok, container_name} when a container is found and deleted for the given function",
         %{function: function} do
      %{name: function_name} = function

      {:ok, {_, [_container = %Worker.Domain.Container{name: container_name} | _]}} =
        Worker.FunctionStorage.Mock.get_function_containers(function_name)

      assert Api.cleanup(function) == {:ok, container_name}
    end

    test "cleanup should return {:error, err} when no container is found for the given function",
         %{function: function} do
      Worker.FunctionStorage.Mock
      |> Mox.stub(:get_function_containers, fn _function_name ->
        {:error, "generic error"}
      end)

      assert {:error, "generic error"} == Api.cleanup(function)
    end
  end
end

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

defmodule ApiTest.CleanupTest do
  # use ExUnit.Case, async: true

  # alias Worker.Domain.Api
  # import Mox, only: [verify_on_exit!: 1]

  # setup :verify_on_exit!

  # setup_all do
  #   function = %{
  #     name: "hellojs",
  #     namespace: "_",
  #     image: "nodejs",
  #     code: "console.log(\"hello\")"
  #   }

  #   %{function: function}
  # end

  # describe "Worker.Api cleanup" do
  #   setup do
  #     Worker.Runtime.Mock |> Mox.stub_with(Worker.Adapters.Runtime.Test)
  #     Worker.RuntimeTracker.Mock |> Mox.stub_with(Worker.Adapters.RuntimeTracker.Test)
  #     :ok
  #   end

  #   test "cleanup should return {:ok, runtime} when a runtime is found and deleted for the given function",
  #        %{function: function} do
  #     [runtime | _] = Worker.RuntimeTracker.Mock.get_runtimes(function.name)

  #     assert Api.Cleanup.cleanup(function) == {:ok, runtime}
  #   end

  #   test "cleanup should return {:error, err} when no runtime is found for the given function",
  #        %{function: function} do
  #     Worker.RuntimeTracker.Mock |> Mox.expect(:get_runtimes, fn _ -> [] end)

  #     assert {:error, "no runtime found to cleanup"} == Api.Cleanup.cleanup(function)
  #   end

  #   test "cleanup_all should return {:ok, []} when all runtimes are deleted without errors for the given function",
  #        %{function: function} do
  #     Worker.RuntimeTracker.Mock
  #     |> Mox.expect(:get_runtimes, fn _ ->
  #       [
  #         %Worker.Domain.RuntimeStruct{name: "runtime1", host: "localhost", port: "8080"},
  #         %Worker.Domain.RuntimeStruct{name: "runtime2", host: "localhost", port: "8081"}
  #       ]
  #     end)

  #     assert Api.Cleanup.cleanup_all(function) == {:ok, []}
  #   end

  #   test "cleanup_all should return {:error, err} when no runtime is found for the given function",
  #        %{function: function} do
  #     Worker.RuntimeTracker.Mock |> Mox.expect(:get_runtimes, fn _ -> [] end)

  #     assert {:error, "no runtime found to cleanup"} == Api.Cleanup.cleanup_all(function)
  #   end

  #   test "cleanup_all should return {:error, [{runtime, err}, ... ]} when errors are encountered while deleting the runtimes",
  #        %{function: function} do
  #     Worker.RuntimeTracker.Mock
  #     |> Mox.expect(:get_runtimes, fn _ ->
  #       [
  #         %Worker.Domain.RuntimeStruct{name: "runtime1", host: "localhost", port: "8080"},
  #         %Worker.Domain.RuntimeStruct{name: "runtime2", host: "localhost", port: "8081"}
  #       ]
  #     end)

  #     Worker.Runtime.Mock
  #     |> Mox.expect(
  #       :cleanup,
  #       2,
  #       fn r ->
  #         case r do
  #           %Worker.Domain.RuntimeStruct{name: "runtime1"} -> {:error, "error"}
  #           _ -> {:ok, r}
  #         end
  #       end
  #     )

  #     assert {:error,
  #             [
  #               {"runtime1", "error"}
  #             ]} ==
  #              Api.Cleanup.cleanup_all(function)
  #   end
  # end
end

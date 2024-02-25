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

defmodule Core.Unit.Policies.DefaultPolicyTest do
  use ExUnit.Case, async: true

  alias Core.Domain.Policies.SchedulingPolicy
  alias Data.Configurations.Empty
  alias Data.FunctionMetadata
  alias Data.FunctionStruct
  alias Data.Worker
  alias Data.Worker.Metrics

  setup_all do
    implementation = SchedulingPolicy.impl_for(%Empty{})
    %{impl: implementation}
  end

  describe "protocol" do
    test "the module should be a valid implementation of the SchedulingPolicy protocol for the Data.Configurations.Empty type",
         %{impl: def_impl} do
      assert Protocol.assert_impl!(SchedulingPolicy, Empty) == :ok
      assert def_impl != nil
    end
  end

  describe "select" do
    setup do
      wrk = %Worker{
        name: "worker@localhost",
        long_name: "worker1",
        concurrent_functions: 0,
        resources: %Metrics{
          memory: %{available: 256, total: 512}
        }
      }

      workers = [
        wrk,
        wrk
        |> Map.put(:long_name, "worker2")
      ]

      function = %FunctionStruct{
        name: "test-func",
        module: "test-mod",
        hash: <<0, 0, 0>>,
        metadata: %FunctionMetadata{
          capacity: 128
        }
      }

      %{
        workers: workers,
        function: function
      }
    end

    test "select should return the worker with the highest amount of memory available",
         %{impl: def_impl, workers: [wrk1, wrk2], function: function} do
      # this test case will break if we change the inner logic of the default scheduling policy
      wrk2 = wrk2 |> Map.put(:resources, %Metrics{memory: %{available: 512, total: 512}})
      {:ok, wrk} = def_impl.select(%Empty{}, [wrk1, wrk2], function)
      assert wrk2 == wrk
    end

    test "select should return {:error, :no_workers} when given an empty worker list",
         %{impl: def_impl, function: function} do
      assert def_impl.select(%Empty{}, [], function) == {:error, :no_workers}
    end

    test "select should return {:error, :no_valid_workers} when given a non-empty worker list, but finding no valid workers",
         %{impl: def_impl, workers: [wrk1, wrk2], function: function} do
      wrk1 =
        wrk1
        |> Map.put(:resources, %Metrics{
          memory: %{available: 0, total: 256}
        })

      wrk2 =
        wrk2
        |> Map.put(:resources, %Metrics{
          memory: %{available: 0, total: 256}
        })

      invalidate_workers = [wrk1, wrk2]

      assert def_impl.select(%Empty{}, invalidate_workers, function) ==
               {:error, :no_valid_workers}
    end

    test "select should return {:error, :no_function_metadata} when given a function with no associated metadata",
         %{impl: def_impl, workers: workers} do
      function = %FunctionStruct{
        name: "test-func",
        module: "test-mod",
        hash: <<0, 0, 0>>
      }

      assert def_impl.select(%Empty{}, workers, function) ==
               {:error, :no_function_metadata}
    end
  end
end

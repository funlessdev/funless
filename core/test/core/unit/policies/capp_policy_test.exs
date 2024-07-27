# Copyright 2024 Giuseppe De Palma, Matteo Trentin
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

defmodule Core.Unit.Policies.CappPolicyTest do
  use ExUnit.Case, async: true

  alias Core.Adapters.Commands.Worker
  alias Core.Domain.Policies.SchedulingPolicy
  alias Core.Domain.Policies.Support.CappEquations
  alias Data.Configurations.CAPP
  alias Data.Configurations.CAPP.Block
  alias Data.Configurations.CAPP.Tag
  alias Data.FunctionMetadata
  alias Data.FunctionStruct
  alias Data.Worker
  alias Data.Worker.Metrics

  setup_all do
    implementation = SchedulingPolicy.impl_for(%CAPP{})
    %{impl: implementation}
  end

  describe "protocol" do
    test "the module should be a valid implementation of the SchedulingPolicy protocol for the Data.Configurations.CAPP type",
         %{impl: app_impl} do
      assert Protocol.assert_impl!(SchedulingPolicy, CAPP) == :ok
      assert app_impl != nil
    end
  end

  describe "get_worker_latencies" do
    test "get_worker_latencies should return the total latency associated to each worker", %{
      impl: app_impl
    } do
      workers = [
        %Worker{
          name: :worker1,
          resources: %Metrics{latencies: %{"example.com" => 100, "example.org" => 150}}
        },
        %Worker{
          name: :worker2,
          resources: %Metrics{latencies: %{"example.com" => 50, "example.org" => 30}}
        }
      ]

      [w1, w2] = workers

      urls = ["example.com", "example.org"]
      equation = "nat(A) + 2 * nat(B)" |> CappEquations.tokenize() |> CappEquations.parse()

      assert app_impl.get_worker_latencies(workers, urls, equation) == [{w1, 400}, {w2, 110}]
    end

    test "get_worker_latencies should use the given placeholder value when a latency can't be found for a service, on a worker",
         %{impl: app_impl} do
      workers = [
        %Worker{
          name: :worker1,
          resources: %Metrics{latencies: %{"example.com" => 100}}
        },
        %Worker{
          name: :worker2,
          resources: %Metrics{latencies: %{"example.org" => 30}}
        }
      ]

      [w1, w2] = workers

      urls = ["example.com", "example.org"]
      equation = "nat(A) + 2 * nat(B)" |> CappEquations.tokenize() |> CappEquations.parse()

      assert app_impl.get_worker_latencies(workers, urls, equation, 1000) == [
               {w1, 2100},
               {w2, 1060}
             ]
    end
  end

  describe "is_valid?" do
    test "is_valid? should return true when invalidate options are :infinity and the worker can host the function",
         %{impl: app_impl} do
      wrk = %Worker{
        name: "worker@localhost",
        concurrent_functions: 100,
        resources: %Metrics{
          memory: %{available: 128, total: 256}
        }
      }

      function = %FunctionStruct{
        name: "test-func",
        module: "test-mod",
        hash: <<0, 0, 0>>,
        metadata: %FunctionMetadata{
          capacity: 128
        }
      }

      invalidate_capacity = :infinity
      invalidate_invocations = :infinity
      invalidate_latency = :infinity

      assert app_impl.is_valid?(
               {wrk, 500},
               function,
               invalidate_capacity,
               invalidate_invocations,
               invalidate_latency
             ) == true
    end

    test "is_valid? should return true when invalidate options are satisfied and the worker can host the function",
         %{impl: app_impl} do
      wrk = %Worker{
        name: "worker@localhost",
        concurrent_functions: 0,
        resources: %Metrics{
          memory: %{available: 256, total: 256}
        }
      }

      function = %FunctionStruct{
        name: "test-func",
        module: "test-mod",
        hash: <<0, 0, 0>>,
        metadata: %FunctionMetadata{
          capacity: 128
        }
      }

      invalidate_capacity = 50
      invalidate_invocations = 1
      invalidate_latency = 500

      assert app_impl.is_valid?(
               {wrk, 500},
               function,
               invalidate_capacity,
               invalidate_invocations,
               invalidate_latency
             ) == true
    end

    test "is_valid? should return false when invalidate options are :infinity and the worker can't host the function",
         %{impl: app_impl} do
      wrk = %Worker{
        name: "worker@localhost",
        concurrent_functions: 0,
        resources: %Metrics{
          memory: %{available: 127, total: 256}
        }
      }

      function = %FunctionStruct{
        name: "test-func",
        module: "test-mod",
        hash: <<0, 0, 0>>,
        metadata: %FunctionMetadata{
          capacity: 128
        }
      }

      invalidate_capacity = :infinity
      invalidate_invocations = :infinity
      invalidate_latency = :infinity

      assert app_impl.is_valid?(
               {wrk, 500},
               function,
               invalidate_capacity,
               invalidate_invocations,
               invalidate_latency
             ) == false
    end

    test "is_valid? should return false when invalidate options are not satisfied or the worker can't host the function",
         %{impl: app_impl} do
      wrk = %Worker{
        name: "worker@localhost",
        concurrent_functions: 0,
        resources: %Metrics{
          memory: %{available: 128, total: 256}
        }
      }

      function = %FunctionStruct{
        name: "test-func",
        module: "test-mod",
        hash: <<0, 0, 0>>,
        metadata: %FunctionMetadata{
          capacity: 128
        }
      }

      invalidate_capacity = 50
      invalidate_invocations = 1
      invalidate_latency = 100

      assert app_impl.is_valid?(
               {wrk |> Map.put(:resources, %Metrics{memory: %{available: 128, total: 192}}), 100},
               function,
               invalidate_capacity,
               invalidate_invocations,
               invalidate_latency
             ) == false

      assert app_impl.is_valid?(
               {wrk |> Map.put(:concurrent_functions, 1), 100},
               function,
               invalidate_capacity,
               invalidate_invocations,
               invalidate_latency
             ) == false

      assert app_impl.is_valid?(
               {wrk, 200},
               function,
               invalidate_capacity,
               invalidate_invocations,
               invalidate_latency
             ) == false

      assert app_impl.is_valid?(
               {wrk |> Map.put(:resources, %Metrics{memory: %{available: 127, total: 256}}), 100},
               function,
               invalidate_capacity,
               invalidate_invocations,
               invalidate_latency
             ) == false
    end
  end

  describe "select" do
    setup do
      latencies1 = %{"example.com" => 50, "example.org" => 30}
      latencies2 = %{"example.com" => 80, "example.org" => 10}
      latencies3 = %{"example.com" => 40, "example.org" => 40}

      wrk = %Worker{
        name: "worker@localhost",
        long_name: "worker1",
        concurrent_functions: 0,
        resources: %Metrics{
          memory: %{available: 256, total: 256}
        }
      }

      workers = [
        wrk |> Map.put(:resources, wrk.resources |> Map.put(:latencies, latencies1)),
        wrk
        |> Map.put(:resources, wrk.resources |> Map.put(:latencies, latencies2))
        |> Map.put(:long_name, "worker2"),
        wrk
        |> Map.put(:resources, wrk.resources |> Map.put(:latencies, latencies3))
        |> Map.put(:long_name, "worker3")
      ]

      script = %CAPP{
        tags: %{
          "test-tag" => %Tag{
            blocks: [
              %Block{
                workers: "*",
                strategy: :min_latency,
                invalidate: %{
                  capacity_used: :infinity,
                  max_concurrent_invocations: :infinity,
                  max_latency: :infinity
                }
              }
            ],
            followup: :default
          }
        }
      }

      equation = "nat(A) + 2*nat(B)"

      function = %FunctionStruct{
        name: "test-func",
        module: "test-mod",
        hash: <<0, 0, 0>>,
        metadata: %FunctionMetadata{
          capacity: 128,
          tag: "test-tag",
          miniSL_equation: equation |> CappEquations.tokenize() |> CappEquations.parse(),
          miniSL_services: [{:get, "example.com", [], []}, {:get, "example.org", [], []}]
        }
      }

      %{
        workers: workers,
        script: script,
        function: function
      }
    end

    test "select should return the valid worker with the minimum latency when the strategy is :min_latency",
         %{
           impl: app_impl,
           workers: [wrk, wrk2, wrk3] = workers,
           script: script,
           function: function
         } do
      assert app_impl.select(script, workers, function) == {:ok, wrk2}

      workers_invalid_second = [
        wrk,
        wrk2
        |> Map.put(:resources, %Metrics{
          memory: %{available: 0, total: 256}
        }),
        wrk3
      ]

      assert app_impl.select(script, workers_invalid_second, function) == {:ok, wrk}

      workers_invalid_first_second = [
        wrk
        |> Map.put(:resources, %Metrics{
          memory: %{available: 0, total: 256}
        }),
        wrk2
        |> Map.put(:resources, %Metrics{
          memory: %{available: 0, total: 256}
        }),
        wrk3
      ]

      assert app_impl.select(script, workers_invalid_first_second, function) == {:ok, wrk3}
    end

    test "select should not select workers that exceed the :max_latency invalidate parameter",
         %{
           impl: app_impl,
           workers: workers,
           function: function
         } do
      script_invalidate = %CAPP{
        tags: %{
          "test-tag" => %Tag{
            blocks: [
              %Block{
                workers: "*",
                strategy: :min_latency,
                invalidate: %{
                  capacity_used: :infinity,
                  max_concurrent_invocations: :infinity,
                  max_latency: 90
                }
              }
            ],
            followup: :default
          }
        }
      }

      assert app_impl.select(script_invalidate, workers, function) == {:error, :no_valid_workers}
    end
  end
end

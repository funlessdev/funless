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

defmodule Core.Unit.Policies.AppPolicyTest do
  use ExUnit.Case, async: true

  alias Core.Domain.Policies.SchedulingPolicy
  alias Data.Configurations.APP
  alias Data.Configurations.APP.Block
  alias Data.Configurations.APP.Tag
  alias Data.FunctionMetadata
  alias Data.FunctionStruct
  alias Data.Worker
  alias Data.Worker.Metrics

  setup_all do
    implementation = SchedulingPolicy.impl_for(%APP{})
    %{impl: implementation}
  end

  describe "protocol" do
    test "the module should be a valid implementation of the SchedulingPolicy protocol for the Data.Configurations.APP type",
         %{impl: app_impl} do
      assert Protocol.assert_impl!(SchedulingPolicy, APP) == :ok
      assert app_impl != nil
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
        metadata: %FunctionMetadata{
          capacity: 128
        }
      }

      invalidate_capacity = :infinity
      invalidate_invocations = :infinity

      assert app_impl.is_valid?(
               wrk,
               function,
               invalidate_capacity,
               invalidate_invocations
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
        metadata: %FunctionMetadata{
          capacity: 128
        }
      }

      invalidate_capacity = 50
      invalidate_invocations = 1

      assert app_impl.is_valid?(
               wrk,
               function,
               invalidate_capacity,
               invalidate_invocations
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
        metadata: %FunctionMetadata{
          capacity: 128
        }
      }

      invalidate_capacity = :infinity
      invalidate_invocations = :infinity

      assert app_impl.is_valid?(
               wrk,
               function,
               invalidate_capacity,
               invalidate_invocations
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
        metadata: %FunctionMetadata{
          capacity: 128
        }
      }

      invalidate_capacity = 49
      invalidate_invocations = 1

      assert app_impl.is_valid?(
               wrk,
               function,
               invalidate_capacity,
               invalidate_invocations
             ) == false

      assert app_impl.is_valid?(
               wrk |> Map.put(:concurrent_functions, 1),
               function,
               invalidate_capacity,
               invalidate_invocations
             ) == false

      assert app_impl.is_valid?(
               wrk |> Map.put(:resources, %Metrics{memory: %{available: 127, total: 256}}),
               function,
               invalidate_capacity,
               invalidate_invocations
             ) == false
    end
  end

  describe "select" do
    setup do
      wrk = %Worker{
        name: "worker@localhost",
        long_name: "worker1",
        concurrent_functions: 0,
        resources: %Metrics{
          memory: %{available: 256, total: 256}
        }
      }

      workers = [
        wrk,
        wrk |> Map.put(:long_name, "worker2"),
        wrk |> Map.put(:long_name, "worker3")
      ]

      script = %APP{
        tags: %{
          "test-tag" => %Tag{
            blocks: [
              %Block{
                affinity: %{affinity: [], antiaffinity: []},
                workers: ["worker1", "worker2"],
                strategy: :"best-first",
                invalidate: %{
                  capacity_used: :infinity,
                  max_concurrent_invocations: :infinity
                }
              }
            ],
            followup: :default
          },
          "default" => %Tag{
            blocks: [
              %Block{
                affinity: %{affinity: [], antiaffinity: []},
                workers: ["worker3"],
                strategy: :"best-first",
                invalidate: %{
                  capacity_used: :infinity,
                  max_concurrent_invocations: :infinity
                }
              }
            ],
            followup: :fail
          }
        }
      }

      script_no_default = %APP{
        tags: script.tags |> Map.put("default", nil)
      }

      function = %FunctionStruct{
        name: "test-func",
        module: "test-mod",
        metadata: %FunctionMetadata{
          capacity: 128,
          tag: "test-tag"
        }
      }

      %{
        workers: workers,
        script: script,
        script_no_default: script_no_default,
        function: function
      }
    end

    test "select should return the first valid worker in the script when the strategy is :best-first",
         %{
           impl: app_impl,
           workers: [wrk, wrk2, wrk3] = workers,
           script: script,
           function: function
         } do
      assert app_impl.select(script, workers, function) == {:ok, wrk}
      assert app_impl.is_valid?(wrk, function, :infinity, :infinity)

      # invalidating the first worker causes select() to choose "worker2"
      workers_invalid_first = [
        wrk
        |> Map.put(:resources, %Metrics{
          memory: %{available: 0, total: 256}
        }),
        wrk2,
        wrk3
      ]

      assert app_impl.select(script, workers_invalid_first, function) == {:ok, wrk2}
      assert app_impl.is_valid?(wrk2, function, :infinity, :infinity)
    end

    test "select should return a valid worker in the script when the strategy is :random",
         %{impl: app_impl, workers: workers, script: script, function: function} do
      {:ok, wrk} = app_impl.select(script, workers, function)
      assert app_impl.is_valid?(wrk, function, :infinity, :infinity)
      assert Enum.member?(workers, wrk) == true
    end

    test "select should return the same result as the default scheduling when the strategy is :platform",
         %{impl: app_impl, workers: workers, function: function, script: script} do
      # regardless of the default scheduling implementation,
      # the APP scheduler must use that policy when the "platform" strategy is given
      default_impl = SchedulingPolicy.impl_for(%Data.Configurations.Empty{})
      [main_block | _] = Map.get(script.tags, "test-tag") |> Map.get(:blocks)

      platform_script = %APP{
        tags:
          script.tags
          |> Map.put("test-tag", %Tag{blocks: [main_block |> Map.put(:strategy, :platform)]})
      }

      {:ok, wrk} = app_impl.select(platform_script, workers, function)
      {:ok, wrk_default} = default_impl.select(%Data.Configurations.Empty{}, workers, function)

      assert app_impl.is_valid?(wrk, function, :infinity, :infinity)
      assert Enum.member?(workers, wrk) == true
      assert wrk_default == wrk
    end

    test "select should use the default tag when the function's tag is not found in the script, but the default tag is defined",
         %{impl: app_impl, workers: [_, _, wrk3] = workers, script: script} do
      function = %FunctionStruct{
        name: "test-func",
        module: "test-mod",
        metadata: %FunctionMetadata{
          tag: "non-existent-tag",
          capacity: 128
        }
      }

      assert app_impl.select(script, workers, function) == {:ok, wrk3}

      only_default_script = %APP{
        tags: %{"default" => Map.get(script.tags, "default")}
      }

      assert app_impl.select(script, workers, function) ==
               app_impl.select(only_default_script, workers, function)
    end

    test "select should use the default tag when no valid workers are found and followup is :default",
         %{impl: app_impl, workers: [wrk1, wrk2, wrk3], script: script, function: function} do
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

      invalidate_workers = [wrk1, wrk2, wrk3]

      assert app_impl.select(script, invalidate_workers, function) == {:ok, wrk3}

      only_default_script = %APP{
        tags: %{"default" => Map.get(script.tags, "default")}
      }

      assert app_impl.select(script, invalidate_workers, function) ==
               app_impl.select(only_default_script, invalidate_workers, function)
    end

    test "select should pick from all existing workers when :workers is *",
         %{impl: app_impl, workers: workers, script: script, function: function} do
      [_wrk1, wrk2, wrk3] = workers
      [main_block | _] = Map.get(script.tags, "test-tag") |> Map.get(:blocks)

      star_workers_script = %APP{
        tags:
          script.tags |> Map.put("test-tag", %Tag{blocks: [main_block |> Map.put(:workers, "*")]})
      }

      list_workers_script = %APP{
        tags:
          script.tags
          |> Map.put("test-tag", %Tag{
            blocks: [
              main_block |> Map.put(:workers, ["worker1", "worker2", "worker3"])
            ]
          })
      }

      # the "*" specification for workers selects all workers currently available as potential hosts for the function
      assert app_impl.select(star_workers_script, workers, function) ==
               app_impl.select(list_workers_script, workers, function)

      list_workers_script = %APP{
        tags:
          script.tags
          |> Map.put("test-tag", %Tag{
            blocks: [
              main_block |> Map.put(:workers, ["worker2", "worker3"])
            ]
          })
      }

      assert app_impl.select(star_workers_script, [wrk2, wrk3], function) ==
               app_impl.select(list_workers_script, [wrk2, wrk3], function)

      list_workers_script = %APP{
        tags:
          script.tags
          |> Map.put("test-tag", %Tag{
            blocks: [
              main_block |> Map.put(:workers, ["worker3"])
            ]
          })
      }

      assert app_impl.select(star_workers_script, [wrk3], function) ==
               app_impl.select(list_workers_script, [wrk3], function)
    end

    test "select should keep iterating over blocks when the first one has no valid workers",
         %{
           impl: app_impl,
           workers: [wrk1, wrk2, wrk3] = workers,
           script: script,
           function: function
         } do
      wrk1_inv =
        wrk1
        |> Map.put(:resources, %Metrics{
          memory: %{available: 0, total: 256}
        })

      wrk2_inv =
        wrk2
        |> Map.put(:resources, %Metrics{
          memory: %{available: 0, total: 256}
        })

      invalidate_workers = [wrk1_inv, wrk2_inv, wrk3]

      [main_block | _] = Map.get(script.tags, "test-tag") |> Map.get(:blocks)
      additional_block = main_block |> Map.put(:workers, ["worker3"])

      two_block_script = %APP{
        tags: script.tags |> Map.put("test-tag", %Tag{blocks: [main_block, additional_block]})
      }

      one_block_script = %APP{
        tags: script.tags |> Map.put("test-tag", %Tag{blocks: [additional_block]})
      }

      # first check the unmodified script on the valid workers is actually working as intended
      # (not part of the test, but nice to have in case it breaks)
      assert app_impl.select(script, workers, function) == {:ok, wrk1}

      # the result should be the same, whether wrk1 and wrk2 are invalid or not when using one_block_script
      assert app_impl.select(two_block_script, invalidate_workers, function) == {:ok, wrk3}

      assert app_impl.select(two_block_script, invalidate_workers, function) ==
               app_impl.select(one_block_script, invalidate_workers, function)

      assert app_impl.select(two_block_script, invalidate_workers, function) ==
               app_impl.select(one_block_script, workers, function)
    end

    test "select should filter out workers that do not exist",
         %{impl: app_impl, workers: [wrk1, _, _] = workers, script: script, function: function} do
      [main_block | _] = Map.get(script.tags, "test-tag") |> Map.get(:blocks)

      bad_wrk_block =
        main_block |> Map.put(:workers, ["bad-wrk1", "bad-wrk2", "worker1", "worker2"])

      bad_wrk_script = %APP{
        tags: script.tags |> Map.put("test-tag", %Tag{blocks: [bad_wrk_block]})
      }

      assert app_impl.select(bad_wrk_script, workers, function) == {:ok, wrk1}

      assert app_impl.select(bad_wrk_script, workers, function) ==
               app_impl.select(script, workers, function)
    end

    test "select should return {:error, :no_workers} when given an empty worker list",
         %{impl: app_impl, script: script, function: function} do
      assert app_impl.select(script, [], function) == {:error, :no_workers}
    end

    test "select should return {:error, :no_valid_workers} when given a non-empty worker list, but finding no valid workers" do
    end

    test "select should return {:error, :no_matching_tag} when the function's tag is not found in the script and default tag is undefined",
         %{impl: app_impl, workers: workers, script_no_default: script_no_default} do
      function = %FunctionStruct{
        name: "test-func",
        module: "test-mod",
        metadata: %FunctionMetadata{
          tag: "non-existent-tag",
          capacity: 128
        }
      }

      assert app_impl.select(script_no_default, workers, function) == {:error, :no_matching_tag}
    end

    test "select should return {:error, :no_function_metadata} when given a function with no associated metadata",
         %{impl: app_impl, workers: workers, script: script} do
      function = %FunctionStruct{
        name: "test-func",
        module: "test-mod"
      }

      assert app_impl.select(script, workers, function) ==
               {:error, :no_function_metadata}
    end

    test "select should return {:error, :invalid_input} when given broken or incomplete data",
         %{impl: app_impl, workers: workers, script: script, function: function} do
      assert app_impl.select(%{}, workers, function) ==
               {:error, :invalid_input}

      assert app_impl.select(script, %{}, function) == {:error, :invalid_input}

      assert app_impl.select(script, workers, %{}) == {:error, :invalid_input}
    end
  end
end

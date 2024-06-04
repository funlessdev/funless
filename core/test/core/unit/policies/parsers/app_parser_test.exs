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

defmodule Core.Unit.Policies.Parsers.AppParserTest do
  use ExUnit.Case, async: true

  alias Core.Domain.Policies.Parsers
  alias Data.Configurations.APP
  alias Data.Configurations.APP.Block
  alias Data.Configurations.APP.Tag

  describe "Parser" do
    test "parse should contain {:error, :no_block_workers} if a tag without blocks is given" do
      script = File.read!("test/support/fixtures/APP/no_workers.yml")

      assert Parsers.APP.parse(script) ==
               {:error, %{"t" => {:error, [{:error, :no_block_workers}]}}}
    end

    test "parse should contain {:error, :no_blocks} if a tag without blocks is given" do
      script = File.read!("test/support/fixtures/APP/no_blocks.yml")

      assert Parsers.APP.parse(script) == {:error, %{"t2" => {:error, :no_blocks}}}
    end

    test "parse should contain {:error, :unknown_followup} if a tag includes a followup other than 'fail' or 'default'" do
      script = File.read!("test/support/fixtures/APP/unknown_followup.yml")

      assert Parsers.APP.parse(script) == {:error, %{"t" => {:error, :unknown_followup}}}
    end

    test "parse should contain {:error, :unknown_construct} if a tag defines something other than blocks and followup" do
      script = File.read!("test/support/fixtures/APP/unknown_construct.yml")

      assert Parsers.APP.parse(script) == {:error, %{"construct" => {:error, :unknown_construct}}}
    end

    test "parse should return a valid APP struct when given a correct script (invalidate.yml)" do
      script = File.read!("test/support/fixtures/APP/invalidate.yml")

      assert {:ok,
              %APP{
                tags: %{
                  "t" => %Tag{
                    blocks: [
                      %Block{
                        affinity: %{affinity: [], antiaffinity: []},
                        workers: ["w1", "w2"],
                        invalidate: %{
                          capacity_used: 50,
                          max_concurrent_invocations: 3
                        }
                      }
                    ],
                    followup: :fail
                  }
                }
              }} == Parsers.APP.parse(script)
    end

    test "parse should return a valid APP struct when given a correct script (producer_consumer.yml)" do
      script = File.read!("test/support/fixtures/APP/producer_consumer.yml")

      assert {:ok,
              %APP{
                tags: %{
                  "producer" => %Tag{
                    blocks: [
                      %Block{
                        affinity: %{affinity: ["consumer"], antiaffinity: ["heavy"]},
                        workers: ["worker1", "worker2"],
                        strategy: :random,
                        invalidate: %{
                          capacity_used: :infinity,
                          max_concurrent_invocations: :infinity
                        }
                      }
                    ],
                    followup: :fail
                  },
                  "consumer" => %Tag{
                    blocks: [
                      %Block{
                        affinity: %{affinity: ["producer"], antiaffinity: ["heavy"]},
                        workers: ["worker1", "worker2"],
                        strategy: :random,
                        invalidate: %{
                          capacity_used: :infinity,
                          max_concurrent_invocations: :infinity
                        }
                      },
                      %Block{
                        affinity: %{affinity: [], antiaffinity: ["heavy"]},
                        workers: ["worker1", "worker2"],
                        strategy: :random,
                        invalidate: %{
                          capacity_used: :infinity,
                          max_concurrent_invocations: :infinity
                        }
                      }
                    ],
                    followup: :fail
                  },
                  "heavy" => %Tag{
                    blocks: [
                      %Block{
                        affinity: %{affinity: [], antiaffinity: []},
                        workers: ["worker1", "worker2"],
                        strategy: :random,
                        invalidate: %{
                          capacity_used: :infinity,
                          max_concurrent_invocations: :infinity
                        }
                      }
                    ],
                    followup: :fail
                  }
                }
              }} ===
               Parsers.APP.parse(script)
    end

    test "to_map should return the APP struct and its nested struct as a single map" do
      script = File.read!("test/support/fixtures/APP/producer_consumer.yml")
      {:ok, parsed_script} = Parsers.APP.parse(script)

      assert %{
               tags: %{
                 "producer" => %{
                   blocks: [
                     %{
                       affinity: %{affinity: ["consumer"], antiaffinity: ["heavy"]},
                       workers: ["worker1", "worker2"],
                       strategy: :random,
                       invalidate: %{
                         capacity_used: :infinity,
                         max_concurrent_invocations: :infinity
                       }
                     }
                   ],
                   followup: :fail
                 },
                 "consumer" => %{
                   blocks: [
                     %{
                       affinity: %{affinity: ["producer"], antiaffinity: ["heavy"]},
                       workers: ["worker1", "worker2"],
                       strategy: :random,
                       invalidate: %{
                         capacity_used: :infinity,
                         max_concurrent_invocations: :infinity
                       }
                     },
                     %{
                       affinity: %{affinity: [], antiaffinity: ["heavy"]},
                       workers: ["worker1", "worker2"],
                       strategy: :random,
                       invalidate: %{
                         capacity_used: :infinity,
                         max_concurrent_invocations: :infinity
                       }
                     }
                   ],
                   followup: :fail
                 },
                 "heavy" => %{
                   blocks: [
                     %{
                       affinity: %{affinity: [], antiaffinity: []},
                       workers: ["worker1", "worker2"],
                       strategy: :random,
                       invalidate: %{
                         capacity_used: :infinity,
                         max_concurrent_invocations: :infinity
                       }
                     }
                   ],
                   followup: :fail
                 }
               }
             } ===
               Parsers.APP.to_map(parsed_script)
    end

    test "from_string_keys should return an APP struct when fed a map with string keys" do
      script = File.read!("test/support/fixtures/APP/producer_consumer.yml")
      {:ok, parsed_script} = Parsers.APP.parse(script)

      string_keys_script =
        parsed_script |> Parsers.APP.to_map() |> Jason.encode!() |> Jason.decode!()

      assert parsed_script === Parsers.APP.from_string_keys(string_keys_script)
    end
  end
end

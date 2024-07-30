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
defmodule Core.Unit.Policies.Parsers.CappParserTest do
  use ExUnit.Case, async: true

  alias Core.Domain.Policies.Parsers
  alias Data.Configurations.CAPP
  alias Data.Configurations.CAPP.Block
  alias Data.Configurations.CAPP.Tag

  describe "Parser" do
    test "parse should return a valid cAPP struct when given min_latency strategy" do
      script = File.read!("test/support/fixtures/cAPP/min_latency.yml")

      assert {:ok,
              %CAPP{
                tags: %{
                  "tag_a" => %Tag{
                    blocks: [
                      %Block{
                        workers: ["worker1", "worker2"],
                        invalidate: %{
                          capacity_used: :infinity,
                          max_concurrent_invocations: :infinity,
                          max_latency: :infinity
                        },
                        strategy: :min_latency
                      }
                    ],
                    followup: :fail
                  }
                }
              }} == Parsers.CAPP.parse(script)
    end

    test "parse should return a valid cAPP struct when given max_latency invalidate" do
      script = File.read!("test/support/fixtures/cAPP/max_latency.yml")

      assert {:ok,
              %CAPP{
                tags: %{
                  "tag_a" => %Tag{
                    blocks: [
                      %Block{
                        workers: ["worker1", "worker2"],
                        invalidate: %{
                          capacity_used: :infinity,
                          max_concurrent_invocations: :infinity,
                          max_latency: 500
                        },
                        strategy: :"best-first"
                      }
                    ],
                    followup: :fail
                  }
                }
              }} == Parsers.CAPP.parse(script)
    end
  end
end

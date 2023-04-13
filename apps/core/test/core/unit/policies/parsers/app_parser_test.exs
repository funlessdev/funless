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

  import(Mox, only: [verify_on_exit!: 1])

  setup :verify_on_exit!

  describe "Parser" do
    test "parse should return {:error, :no_blocks} if a tag without blocks is given" do
      script = File.read!("test/support/fixtures/APP/no_blocks.yml")
    end

    test "parse should return {:error, :unknown_followup} if a tag includes a followup other than 'fail' or 'default'" do
      script = File.read!("test/support/fixtures/APP/unknown_followup.yml")
    end

    test "parse should return {:error, :unknown_construct} if a tag defines something other than blocks and followup" do
      script = File.read!("test/support/fixtures/APP/unknown_construct.yml")
    end

    test "parse should return a valid APP struct when given a correct script (invalidate.yml)" do
      script = File.read!("test/support/fixtures/APP/invalidate.yml")
    end

    test "parse should return a valid APP struct when given a correct script (producer_consumer.yml)" do
      script = File.read!("test/support/fixtures/APP/producer_consumer.yml")
    end
  end
end

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

defmodule ApiTest.UtilTest do
  alias Core.Domain.Api.Utils
  use ExUnit.Case
  use Plug.Test

  describe "API.Utils" do
    test "validate_namespace should return _ if the given namespace is nil" do
      expected = "_"
      assert Utils.validate_namespace(nil) == expected
    end

    test "validate_namespace should return _ if the given namespace is empty" do
      expected = "_"
      assert Utils.validate_namespace("") == expected
    end

    test "validate_namespace should return _ if the given namespace is only whitespace" do
      expected = "_"
      assert Utils.validate_namespace("    ") == expected
      assert Utils.validate_namespace("\n\n\n\n") == expected
      assert Utils.validate_namespace(" \t\n \n\t ") == expected
    end

    test "validate_namespace should return the trimmed input if it is not empty, blank nor nil" do
      expected = "ns"

      input = "\n\nns\n\n"
      assert Utils.validate_namespace(input) == expected

      input = "\n\nns  "
      assert Utils.validate_namespace(input) == expected

      input = "\tns\r\n"
      assert Utils.validate_namespace(input) == expected

      input = "ns"
      assert Utils.validate_namespace(input) == expected

      input = "n s"
      expected = "n s"
      assert Utils.validate_namespace(input) == expected
    end
  end
end

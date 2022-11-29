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

defmodule Support.AssertionHelpers do
  @moduledoc false
  import ExUnit.Assertions

  def assert_error_keys(json) do
    actual_errors = json["errors"]
    expected_error_keys = ["detail"]
    assert_json_has_correct_keys(actual: actual_errors, expected: expected_error_keys)
  end

  def assert_json_has_correct_keys(lists) do
    actual = Keyword.fetch!(lists, :actual)
    refute Enum.empty?(actual)

    expected = Keyword.fetch!(lists, :expected)
    assert Enum.sort(expected) == Enum.sort(Map.keys(actual))
  end
end

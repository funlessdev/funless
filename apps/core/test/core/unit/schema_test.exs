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

defmodule Core.Unit.SchemaTest do
  use ExUnit.Case, async: true

  alias Core.Schemas.Function
  alias Core.Schemas.Module

  test "invalid names for module" do
    test_cases = [
      "$",
      "-",
      " ",
      "invalid-",
      "invalid ",
      "invalid name",
      "invalid-name",
      "_ "
    ]

    for test_case <- test_cases do
      set = Module.changeset(%Module{}, %{name: test_case})

      assert set.valid? == false
    end
  end

  test "invalid names for function" do
    test_cases = [
      "$",
      "-",
      " ",
      "invalid-",
      "invalid ",
      "invalid name",
      "invalid-name",
      "_ "
    ]

    for test_case <- test_cases do
      set = Function.changeset(%Function{}, %{name: test_case, code: "some code"})

      assert set.valid? == false
    end
  end
end

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

defmodule Core.Unit.Policies.Support.CappEquationsTest do
  use ExUnit.Case, async: true
  alias Core.Domain.Policies.Support.CappEquations

  test "tokenize" do
    equations = [
      "max([nat(B), nat(C)])",
      "max([nat(A + 1), nat(B + 5)])",
      "nat(A)+max([nat(B),nat(C)])",
      "nat(C)+nat(A+1)*nat(B)",
      "max([nat(A+1), nat(B)]) + 6*nat(C)",
      "max([nat(A), nat(B)]) * nat(C) + nat(C)"
    ]

    results = [
      [
        :max,
        :lpar,
        :lbrack,
        :nat,
        :lpar,
        {:var, "B"},
        :rpar,
        :comma,
        :nat,
        :lpar,
        {:var, "C"},
        :rpar,
        :rbrack,
        :rpar
      ],
      [
        :max,
        :lpar,
        :lbrack,
        :nat,
        :lpar,
        {:var, "A"},
        :plus,
        {:num, 1},
        :rpar,
        :comma,
        :nat,
        :lpar,
        {:var, "B"},
        :plus,
        {:num, 5},
        :rpar,
        :rbrack,
        :rpar
      ],
      [
        :nat,
        :lpar,
        {:var, "A"},
        :rpar,
        :plus,
        :max,
        :lpar,
        :lbrack,
        :nat,
        :lpar,
        {:var, "B"},
        :rpar,
        :comma,
        :nat,
        :lpar,
        {:var, "C"},
        :rpar,
        :rbrack,
        :rpar
      ],
      [
        :nat,
        :lpar,
        {:var, "C"},
        :rpar,
        :plus,
        :nat,
        :lpar,
        {:var, "A"},
        :plus,
        {:num, 1},
        :rpar,
        :star,
        :nat,
        :lpar,
        {:var, "B"},
        :rpar
      ],
      [
        :max,
        :lpar,
        :lbrack,
        :nat,
        :lpar,
        {:var, "A"},
        :plus,
        {:num, 1},
        :rpar,
        :comma,
        :nat,
        :lpar,
        {:var, "B"},
        :rpar,
        :rbrack,
        :rpar,
        :plus,
        {:num, 6},
        :star,
        :nat,
        :lpar,
        {:var, "C"},
        :rpar
      ],
      [
        :max,
        :lpar,
        :lbrack,
        :nat,
        :lpar,
        {:var, "A"},
        :rpar,
        :comma,
        :nat,
        :lpar,
        {:var, "B"},
        :rpar,
        :rbrack,
        :rpar,
        :star,
        :nat,
        :lpar,
        {:var, "C"},
        :rpar,
        :plus,
        :nat,
        :lpar,
        {:var, "C"},
        :rpar
      ]
    ]

    equations
    |> Enum.zip(results)
    |> Enum.each(fn {eq, res} ->
      tokens = CappEquations.tokenize(eq)
      assert tokens == res
    end)
  end

  test "parse" do
    equations = [
      "max([nat(B), nat(C)])",
      "max([nat(A + 1), nat(B + 5)])",
      "nat(A)+max([nat(B),nat(C)])",
      "nat(C)+nat(A+1)*nat(B)",
      "max([nat(A+1), nat(B)]) + 6*nat(C)",
      "max([nat(A), nat(B)]) * nat(C) + nat(C)"
    ]

    results = [
      {:max, [{:nat, "C"}, {:nat, "B"}]},
      {:max, [{:nat, {:sum, "B", 5}}, {:nat, {:sum, "A", 1}}]},
      {:sum, {:nat, "A"}, {:max, [{:nat, "C"}, {:nat, "B"}]}},
      {:sum, {:nat, "C"}, {:prod, {:nat, {:sum, "A", 1}}, {:nat, "B"}}},
      {:sum, {:max, [{:nat, "B"}, {:nat, {:sum, "A", 1}}]}, {:prod, {:num, 6}, {:nat, "C"}}},
      {:sum, {:prod, {:max, [{:nat, "B"}, {:nat, "A"}]}, {:nat, "C"}}, {:nat, "C"}}
    ]

    equations
    |> Enum.zip(results)
    |> Enum.each(fn {eq, res} ->
      tokens = CappEquations.tokenize(eq)
      tree = CappEquations.parse(tokens)
      assert tree == res
    end)
  end

  test "evaluate" do
    equations = [
      "max([nat(B), nat(C)])",
      "max([nat(A + 1), nat(B + 5)])",
      "nat(A)+max([nat(B),nat(C)])",
      "nat(C)+nat(A+1)*nat(B)",
      "max([nat(A+1), nat(B)]) + 6*nat(C)",
      "max([nat(A), nat(B)]) * nat(C) + nat(C)"
    ]

    vars = %{"A" => 5, "B" => 6, "C" => 7}

    results = [
      7,
      11,
      12,
      43,
      48,
      49
    ]

    equations
    |> Enum.zip(results)
    |> Enum.each(fn {eq, res} ->
      tokens = CappEquations.tokenize(eq)
      tree = CappEquations.parse(tokens)
      val = CappEquations.evaluate(tree, vars)
      assert val == res
    end)
  end
end

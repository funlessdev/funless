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

defmodule Core.Domain.Policies.Support.CappEquations do
  @moduledoc """
    Methods to tokenize, parse and evaluate equations produced by PUBS for programs
    written in miniSL, to be used by cAPP policies.
  """
  @type token ::
          :max
          | :star
          | :plus
          | :lpar
          | :rpar
          | :lbrack
          | :rbrack
          | :comma
          | :nat
          | {:var, binary()}
          | {:num, number()}
  @type nat :: {:nat, binary()} | {:nat, {:sum, binary(), number()}}
  @type max :: {:max, [exp()]}
  @type sum :: {:sum, exp(), exp()}
  @type prod :: {:prod, exp(), exp()}
  @type num :: {:num, number()}
  @type exp :: {} | nat | max | sum | prod | num

  @spec tokenize(String.t()) :: [token()]
  def tokenize(equation) do
    equation = String.replace(equation, " ", "")
    tokenize_chars(equation, [])
  end

  @spec tokenize_chars(String.t(), [token()]) :: [token()]
  defp tokenize_chars(equation, tokens) when equation != "" do
    {token, rest} =
      case equation do
        "+" <> rest ->
          {:plus, rest}

        "*" <> rest ->
          {:star, rest}

        "max" <> rest ->
          {:max, rest}

        "(" <> rest ->
          {:lpar, rest}

        ")" <> rest ->
          {:rpar, rest}

        "[" <> rest ->
          {:lbrack, rest}

        "]" <> rest ->
          {:rbrack, rest}

        "," <> rest ->
          {:comma, rest}

        "nat" <> rest ->
          {:nat, rest}

        str_or_num ->
          if String.match?(str_or_num, ~r/^[0-9]+/) do
            [num] = Regex.run(~r/^[0-9]+/, str_or_num)
            {_, rest} = str_or_num |> String.split_at(String.length(num))
            {{:num, String.to_integer(num)}, rest}
          else
            [str] = Regex.run(~r/^[a-zA-Z0-9_]+/, str_or_num)
            {_, rest} = str_or_num |> String.split_at(String.length(str))
            {{:var, str}, rest}
          end
      end

    tokenize_chars(rest, [token | tokens])
  end

  defp tokenize_chars("", tokens) do
    Enum.reverse(tokens)
  end

  @spec parse([token()]) :: exp()
  def parse([]) do
    {}
  end

  def parse([_ | _] = tokens) do
    {exp, []} = parse_equation(tokens)
    exp
  end

  defp parse_equation(tokens) do
    {left, rest} = parse_prod(tokens)
    loop_parse_equation(left, rest)
  end

  defp loop_parse_equation(left, tokens) do
    case tokens do
      [:plus | rest] ->
        {right, rest} = parse_prod(rest)
        loop_parse_equation({:sum, left, right}, rest)

      _ ->
        {left, tokens}
    end
  end

  defp parse_prod(tokens) do
    {left, rest} = parse_factor(tokens)
    loop_parse_prod(left, rest)
  end

  defp loop_parse_prod(left, tokens) do
    case tokens do
      [:star | rest] ->
        {right, rest} = parse_factor(rest)
        loop_parse_prod({:prod, left, right}, rest)

      _ ->
        {left, tokens}
    end
  end

  defp parse_factor(tokens) do
    case tokens do
      [:max | rest] -> parse_max(rest)
      _ -> parse_primary(tokens)
    end
  end

  defp parse_max(tokens) do
    [:lpar, :lbrack | rest] = tokens
    {params, rest} = parse_params(rest)
    [:rbrack, :rpar | rest] = rest
    {{:max, params}, rest}
  end

  defp parse_params(tokens) do
    {param, rest} = parse_equation(tokens)
    loop_parse_params([param], rest)
  end

  defp loop_parse_params(params, tokens) do
    case tokens do
      [:comma | rest] ->
        {param, rest} = parse_equation(rest)
        loop_parse_params([param | params], rest)

      _ ->
        {params, tokens}
    end
  end

  defp parse_primary(tokens) do
    case tokens do
      [{:num, n} | rest] ->
        {{:num, n}, rest}

      [:nat, :lpar, {:var, var_name}, :rpar | rest] ->
        {{:nat, var_name}, rest}

      [:nat, :lpar, {:var, var_name}, :plus, {:num, n}, :rpar | rest] ->
        {{:nat, {:sum, var_name, n}}, rest}

      [:lpar | rest] ->
        {exp, rest} = parse_equation(rest)
        [:rpar | rest] = rest
        {exp, rest}
    end
  end

  @spec evaluate(exp(), %{binary() => number()}) :: number()
  def evaluate(tree, vars) do
    case tree do
      {:nat, {:sum, var, n}} -> n + Map.get(vars, var)
      {:nat, var} -> Map.get(vars, var)
      {:num, n} -> n
      {:max, exps} -> exps |> Enum.map(fn e -> evaluate(e, vars) end) |> Enum.max()
      {:sum, exp1, exp2} -> evaluate(exp1, vars) + evaluate(exp2, vars)
      {:prod, exp1, exp2} -> evaluate(exp1, vars) * evaluate(exp2, vars)
      _ -> exit(:bad_node)
    end
  end
end

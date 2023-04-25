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

defmodule Core.Domain.Policies.Parsers.APP do
  @on_load :load_atoms

  defp load_atoms do
    [Data.Configurations.APP, Data.Configurations.APP.Block, Data.Configurations.APP.Tag]
    |> Enum.each(&Code.ensure_loaded?/1)

    :ok
  end

  @spec parse(String.t()) ::
          {:ok, Data.Configurations.APP.t()} | {:error, %{String.t() => {:error, any}}}
  def parse(content) do
    with {:ok, yaml} <- YamlElixir.read_from_string(content) do
      yaml |> parse_script()
    end
  end

  @spec parse_script([map()]) ::
          {:ok, Data.Configurations.APP.t()} | {:error, %{String.t() => {:error, any}}}
  def parse_script([_ | _] = yaml) do
    {parsed, errors} =
      yaml
      |> Enum.map(fn tag -> tag |> Map.to_list() |> parse_tag end)
      |> Enum.split_with(&match?({_, {:ok, _}}, &1))

    case errors do
      [] ->
        {:ok,
         %Data.Configurations.APP{
           tags:
             parsed
             |> Enum.map(fn {tag_name, {:ok, tag}} -> {tag_name, tag} end)
             |> Enum.into(%{})
         }}

      [_ | _] ->
        {:error, errors |> Enum.into(%{})}
    end
  end

  def parse_script(_) do
    {:error, :unknown_construct}
  end

  @spec parse_tag([{String.t(), any}]) ::
          {String.t(),
           {:error, :no_blocks | :unknown_construct | :unknown_followup | [{:error, any}]}
           | {:ok, Data.Configurations.APP.Tag.t()}}
  def parse_tag([{"followup", _} = followup, {_, _} = tag]) do
    parse_tag([tag, followup])
  end

  def parse_tag([{tag_name, [_ | _] = blocks}, {"followup", followup}])
      when followup in ["default", "fail"] do
    {parsed, errors} =
      blocks |> Enum.map(&parse_block/1) |> Enum.split_with(&match?({:ok, _}, &1))

    tag_content =
      case errors do
        [] ->
          {:ok,
           %Data.Configurations.APP.Tag{
             blocks:
               parsed
               |> Enum.map(fn {:ok, block} -> block end),
             followup: String.to_existing_atom(followup)
           }}

        [_ | _] ->
          {:error, errors}
      end

    {tag_name, tag_content}
  end

  def parse_tag([{_tag_name, _blocks = [_ | _]} = tag]) do
    parse_tag([tag, {"followup", "fail"}])
  end

  def parse_tag([{tag_name, _blocks = [_ | _]}, {"followup", _}]) do
    {tag_name, {:error, :unknown_followup}}
  end

  def parse_tag([{tag_name, []} | _]) do
    {tag_name, {:error, :no_blocks}}
  end

  def parse_tag([{tag_name, nil} | _]) do
    {tag_name, {:error, :no_blocks}}
  end

  def parse_tag([{tag_name, _} | _]) do
    {tag_name, {:error, :unknown_construct}}
  end

  @spec parse_block(%{String.t() => any}) ::
          {:ok, Data.Configurations.APP.Block.t()} | {:error, :no_block_workers}
  def parse_block(%{"workers" => wrk, "strategy" => strategy} = block)
      when strategy in ["random", "best-first", "platform"] and (is_list(wrk) or is_binary(wrk)) do
    block_with_atom_keys =
      for {k, v} <- block, into: %{} do
        {String.to_existing_atom(k), v}
      end

    {antiaffinity, affinity} =
      block
      |> Map.get("affinity", [])
      |> Enum.split_with(fn t -> t |> String.starts_with?("!") end)

    capacity_used =
      block
      |> Map.get("invalidate", %{})
      |> Map.get("capacity_used", :infinity)
      |> then(fn x ->
        if x != :infinity do
          {n, _} = Integer.parse(x)
          n
        else
          x
        end
      end)

    max_concurrent_invocations =
      block |> Map.get("invalidate", %{}) |> Map.get("max_concurrent_invocations", :infinity)

    {:ok,
     struct(
       Data.Configurations.APP.Block,
       block_with_atom_keys
       |> Map.put(:affinity, %{
         affinity: affinity,
         antiaffinity: antiaffinity |> Enum.map(fn "!" <> s -> s end)
       })
       |> Map.put(:invalidate, %{
         capacity_used: capacity_used,
         max_concurrent_invocations: max_concurrent_invocations
       })
       |> Map.put(:strategy, strategy |> String.to_existing_atom())
     )}
  end

  def parse_block(%{"workers" => wrk} = block)
      when is_list(wrk) or is_binary(wrk) do
    parse_block(block |> Map.put("strategy", "best-first"))
  end

  def parse_block(_) do
    {:error, :no_block_workers}
  end
end

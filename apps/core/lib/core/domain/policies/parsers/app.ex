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
  @spec parse_block(%{String.t() => any}) :: Data.Configurations.APP.Block.t()
  def parse_block(%{"workers" => _, "strategy" => strategy} = block)
      when strategy in ["random", "best-first", "platform"] do
    block_with_atom_keys =
      for {k, v} <- block, into: %{} do
        {String.to_existing_atom(k), v}
      end

    {antiaffinity, affinity} =
      block
      |> Map.get("affinity", [])
      |> Enum.split_with(fn t -> t |> String.starts_with?("!") end)

    capacity_used = block |> Map.get("invalidate", %{}) |> Map.get("capacity_used", :infinity)

    max_concurrent_invocations =
      block |> Map.get("invalidate", %{}) |> Map.get("max_concurrent_invocations", :infinity)

    struct(
      Data.Configurations.APP.Block,
      block_with_atom_keys
      |> Map.put(:affinity, %{
        affinity: affinity,
        antiffinity: antiaffinity |> Enum.map(fn "!" <> s -> s end)
      })
      |> Map.put(:invalidate, %{
        capacity_used: capacity_used,
        max_concurrent_invocations: max_concurrent_invocations
      })
      |> Map.put(:strategy, strategy |> String.to_existing_atom())
    )
  end

  def parse_block(%{"workers" => _} = block) do
    parse_block(block |> Map.put("strategy", "best-first"))
  end

  @spec parse_tag([{String.t(), any}]) ::
          {String.t(),
           {:error, :no_blocks | :unknown_construct | :unknown_followup}
           | {:ok, Data.Configurations.APP.Tag.t()}}
  def parse_tag([{tag_name, [_ | _] = blocks}, {"followup", followup}])
      when followup in ["default", "fail"] do
    {tag_name,
     {:ok,
      %Data.Configurations.APP.Tag{
        blocks: blocks |> Enum.map(&parse_block/1),
        followup: String.to_existing_atom(followup)
      }}}
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

  def parse_tag([{tag_name, _} | _]) do
    {tag_name, {:error, :unknown_construct}}
  end

  @spec parse([map()]) :: Data.Configurations.APP.t() | %{String.t() => {:error, any}}
  def parse_script([_ | _] = yaml) do
    {parsed, errors} =
      yaml
      |> Enum.map(fn tag -> tag |> Map.to_list() |> parse_tag end)
      |> Enum.split_with(&match?({:ok, _}, &1))

    case errors do
      [] -> %Data.Configurations.APP{tags: parsed |> Enum.into(%{})}
      [_ | _] -> errors |> Enum.into(%{})
    end
  end

  @spec parse(String.t()) :: Data.Configurations.APP.t() | %{String.t() => {:error, any}}
  def parse(content) do
    with {:ok, yaml} <- YamlElixir.read_from_string(content) do
      yaml |> parse_script()
    end
  end
end

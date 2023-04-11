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

defimpl Core.Domain.Policies.SchedulingPolicy, for: Data.Configurations.APP do
  alias Data.Configurations.APP
  alias Data.Configurations.APP.Block
  alias Data.Configurations.APP.Tag

  @type select_errors ::
          {:error, :no_workers}
          | {:error, :no_valid_workers}
          | {:error, :invalid_input}
          | {:error, :no_matching_tag}
          | {:error, :no_function_metadata}

  @spec select(Data.Configurations.APP.t(), [Data.Workers.t()], Data.FunctionStruct.t()) ::
          {:ok, Data.Worker.t()} | {:error, :no_matching_tag} | select_errors()
  def select(
        %APP{tags: tags} = _configuration,
        [_ | _] = workers,
        %Data.FunctionStruct{metadata: %{tag: tag_name, capacity: _function_capacity}}
      ) do
    default = tags |> Map.get("default")
    tag = tags |> Map.get(tag_name, default)

    with %Tag{blocks: [_ | _] = blocks, followup: followup} <- tag do
      case {schedule(blocks, workers), followup, default} do
        {nil, :fail, _} ->
          {:error, :no_valid_workers}

        {nil, :default, nil} ->
          {:error, :no_valid_workers}

        {nil, :default, %Tag{blocks: [_ | _] = default_blocks}} ->
          schedule(default_blocks, workers)

        {%Data.Worker{} = wrk, _, _} ->
          {:ok, wrk}
      end
    else
      nil -> {:error, :no_matching_tag}
    end
  end

  def select(_, [], _) do
    {:error, :no_workers}
  end

  def select(%APP{tags: _}, _, %Data.FunctionStruct{}) do
    {:error, :no_function_metadata}
  end

  def select(_, _, _) do
    {:error, :invalid_input}
  end

  defp schedule(
         [
           %Block{
             workers: block_workers,
             strategy: strategy,
             invalidate: %{
               capacity_used: invalidate_capacity,
               max_concurrent_invocations: invalidate_invocations
             }
           }
           | rest
         ],
         workers
       ) do
    filtered_workers =
      block_workers
      |> Enum.with_index(fn w, i -> {i, w} end)
      |> MapSet.new()
      |> MapSet.intersection(MapSet.new(workers))
      |> MapSet.to_list()
      |> Enum.map(fn {_, w} -> w end)
      |> Enum.filter(fn %Data.Worker{concurrent_functions: c} ->
        invalidate_invocations == :infinity or c < invalidate_invocations
      end)
      |> Enum.filter(fn %Data.Worker{
                          resources: %Data.Worker.Metrics{
                            memory: %{available: available, total: total}
                          }
                        } ->
        (total - available) / total * 100 < invalidate_capacity
      end)

    case {filtered_workers, strategy} do
      {[], _} ->
        schedule(rest, workers)

      {[h | _], :"best-first"} ->
        h

      {[_ | _] = wrk, :random} ->
        wrk |> Enum.random()

      {[_ | _] = wrk, :platform} ->
        wrk
        |> Enum.max_by(fn %Data.Worker{resources: %{memory: %{available: available}}} ->
          available
        end)
    end
  end

  defp schedule([], _) do
    nil
  end
end

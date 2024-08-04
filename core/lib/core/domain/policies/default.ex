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

defimpl Core.Domain.Policies.SchedulingPolicy, for: Data.Configurations.Empty do
  alias Data.Configurations.Empty

  # select the worker with the highest available memory; if no memory information is available, it's treated as 0
  # NOTE: we choose to include workers for which we have no data,
  # since otherwise in situations where e.g. Prometheus is down, we would always have no workers
  @spec select(Empty.t(), [Data.Worker.t()], Data.FunctionStruct.t()) ::
          {:ok, Data.Worker.t()} | {:error, :no_workers} | {:error, :no_valid_workers}
  def select(config, workers, function, args \\ %{})

  def select(
        %Empty{},
        [_ | _] = workers,
        %Data.FunctionStruct{metadata: %Data.FunctionMetadata{capacity: c}},
        _
      ) do
    selected_worker =
      workers
      |> Enum.filter(fn
        %Data.Worker{resources: %{memory: %{available: available}}} -> c <= available
        %Data.Worker{} -> true
      end)
      |> Enum.max_by(
        fn
          %Data.Worker{resources: %{memory: %{available: available}}} -> available
          %Data.Worker{} -> 0
        end,
        fn -> nil end
      )

    case selected_worker do
      nil -> {:error, :no_valid_workers}
      %Data.Worker{} = wrk -> {:ok, wrk}
    end
  end

  def select(%Empty{}, _, %Data.FunctionStruct{metadata: nil}, _) do
    {:error, :no_function_metadata}
  end

  def select(%Empty{}, [], _, _) do
    {:error, :no_workers}
  end
end

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

defimpl Core.Domain.Policies.SchedulingPolicy, for: Data.Configurations.CAPP do
  @moduledoc """
  Implementation of the SchedulingPolicy protocol for the CAPP datatype.
  """
  alias Core.Domain.Policies.Support.CappEquations
  alias Core.Domain.Ports.PubsService
  alias Data.Configurations.CAPP
  alias Data.Configurations.CAPP.Block
  alias Data.Configurations.CAPP.Tag

  @unknown_latency 999_999

  @type select_errors ::
          {:error, :no_workers}
          | {:error, :no_valid_workers}
          | {:error, :invalid_input}
          | {:error, :no_matching_tag}
          | {:error, :no_function_metadata}

  @doc """
  Selects a suitable worker to host the given function, according to the provided APP configuration.

  ## Parameters
  - configuration: an APP script (Data.Configurations.APP), generally obtained through parsing using the Core.Domain.Policies.Parsers.APP module.
  - workers: a list of Data.Worker structs, each with relevant worker metrics.
  - function: a Data.FunctionStruct struct, with the necessary function information. It must contain function metadata, specifically a tag and a capacity.
  - args: the function's input parameters

  ## Returns
  - {:ok, wrk} if a suitable worker was found, with `wrk` being the worker.
  - {:error, :no_workers} if an empty list of workers is received.
  - {:error, :no_valid_workers} if no suitable worker was found (but a non-empty list of workers was given in input).
  - {:error, :no_matching_tag} if the function's tag does not exist in the given configuration, and no default tag was specified in it.
  - {:error, :no_function_metadata} if the given FunctionStruct does not include the necessary metadata (i.e. tag, capacity).
  - {:error, :invalid_input} if the given input was invalid in any other way (e.g. wrong types).
  """
  @spec select(CAPP.t(), [Data.Worker.t()], Data.FunctionStruct.t(), map()) ::
          {:ok, Data.Worker.t()} | select_errors()
  def select(
        %CAPP{tags: tags} = _configuration,
        [_ | _] = workers,
        %Data.FunctionStruct{metadata: %{tag: tag_name, capacity: _function_capacity}} = function,
        args
      ) do
    default = tags |> Map.get("default")
    tag = tags |> Map.get(tag_name, default)

    case tag do
      %Tag{blocks: [_ | _] = blocks, followup: followup} ->
        mapped_workers = workers |> Map.new(fn %Data.Worker{long_name: n} = w -> {n, w} end)

        case schedule_on_blocks(blocks, mapped_workers, function, args) do
          {:error, :no_valid_workers}
          when followup == :fail or (followup == :default and is_nil(default)) ->
            {:error, :no_valid_workers}

          {:error, :no_valid_workers} when followup == :default ->
            %Tag{blocks: [_ | _] = default_blocks} = default
            schedule_on_blocks(default_blocks, mapped_workers, function, args)

          {:ok, %Data.Worker{} = wrk} ->
            {:ok, wrk}
        end

      nil ->
        {:error, :no_matching_tag}
    end
  end

  def select(%CAPP{tags: _}, [], _, _) do
    {:error, :no_workers}
  end

  def select(%CAPP{tags: _}, _, %Data.FunctionStruct{metadata: nil}, _) do
    {:error, :no_function_metadata}
  end

  def select(_, _, _, _) do
    {:error, :invalid_input}
  end

  @doc """
  Helper function, recursively explores the blocks specified for a function's tag in an APP configuration.

  ## Parameters
  - blocks: a list of APP blocks (Data.Configurations.APP.Block), extracted from the function's tag definition in the APP configuration.
  - workers: a map with String keys and Data.Worker values; the keys are each worker's "long_name" attribute, which are the same names used inside the APP configuration.
  - function: a Data.FunctionStruct struct, with the necessary function information. It must contain function metadata, specifically a tag and a capacity.

  ## Returns
  - {:ok, wrk} if a suitable worker was found, with `wrk` being the worker.
  - {:error, :no_valid_workers} if no suitable worker was found (but a non-empty list of workers was given in input).
  """
  @spec schedule_on_blocks(
          [Block.t()],
          %{String.t() => Data.Worker.t()},
          Data.FunctionStruct.t(),
          map()
        ) ::
          {:ok, Data.Worker.t()} | {:error, :no_valid_workers}
  def schedule_on_blocks(
        [
          %Block{
            workers: "*"
          } = block
          | rest
        ],
        workers,
        function,
        args
      ) do
    new_block = block |> Map.put(:workers, workers |> Map.keys())
    schedule_on_blocks([new_block | rest], workers, function, args)
  end

  def schedule_on_blocks(
        [
          %Block{
            workers: block_workers,
            strategy: strategy,
            invalidate: %{
              capacity_used: invalidate_capacity,
              max_concurrent_invocations: invalidate_invocations,
              max_latency: invalidate_latency
            }
          }
          | rest
        ],
        workers,
        %Data.FunctionStruct{
          metadata: %{miniSL_services: svc, miniSL_equation: [main_eq | equations]}
        } = function,
        args
      ) do
    urls = svc |> Enum.map(fn {_method, url, _request, _response} -> url end)

    r = ~r/^^eq\(main\([\w,]*\),[\w\(\)]*,\[([\w\(,\)]+\))\],\[[\w,]*\]\)\.$/
    [^main_eq | [inner_block]] = Regex.run(r, main_eq)

    new_inner_block =
      args
      |> Enum.reduce(inner_block, fn {k, v}, block -> String.replace(block, k, to_string(v)) end)

    new_equations = [main_eq |> String.replace(inner_block, new_inner_block) | equations]

    {:ok, equation} = PubsService.compute_upper_bound(new_equations)
    equation = equation |> CappEquations.tokenize() |> CappEquations.parse()

    filtered_workers =
      block_workers
      |> Enum.flat_map(fn w ->
        case Map.get(workers, w) do
          nil -> []
          wrk -> [wrk]
        end
      end)
      |> get_worker_latencies(urls, equation)
      |> Enum.filter(fn {w, latency} ->
        # filter based on max_latency as well
        is_valid?(
          {w, latency},
          function,
          invalidate_capacity,
          invalidate_invocations,
          invalidate_latency
        )
      end)

    case filtered_workers do
      [] ->
        schedule_on_blocks(rest, workers, function)

      [{h, _} | _] = wrk_latencies ->
        case strategy do
          :"best-first" ->
            {:ok, h}

          :random ->
            {wrk, _} = wrk_latencies |> Enum.random()
            {:ok, wrk}

          :platform ->
            wrk = wrk_latencies |> Enum.map(&elem(&1, 0))

            Core.Domain.Policies.SchedulingPolicy.select(
              %Data.Configurations.Empty{},
              wrk,
              function,
              %{}
            )

          :min_latency ->
            # map each worker to a list of latencies for each URL

            {selected, _} = wrk_latencies |> Enum.min_by(fn {_, lat} -> lat end)

            {:ok, selected}
        end
    end
  end

  def schedule_on_blocks([], _, _) do
    {:error, :no_valid_workers}
  end

  @doc """
  Helper function, checks if a worker is valid according to the given "invalidate" options and a certain function.
  The basic validity check consists in ensuring that the worker has enough available memory to host the function, given its capacity.

  ## Parameters
  - {w, latency}: a Data.Worker struct, with defined memory metrics and amount of concurrent functions,
                  and its associated total latency towards services.
  - function: a Data.FunctionStruct struct, with the necessary function information.
              It must contain function metadata, specifically its capacity.
  - invalidate_capacity: either a number or the :infinity atom, it's the maximum memory
                        (percentage relative to the total worker memory) that can
                        be occupied in the worker, before it is considered invalid.
  - invalidate_invocations: either a number or the :infinity atom, it's the maximum number of
                            concurrent functions the worker can host before being considered invalid.

  ## Returns
  - true if the worker can host the function, given the conditions
  - false otherwise
  """
  @spec is_valid?(
          {Data.Worker.t(), number()},
          Data.FunctionStruct.t(),
          number() | :infinity,
          number() | :infinity,
          number() | :infinity
        ) :: boolean
  def is_valid?(
        {%Data.Worker{
           concurrent_functions: c,
           resources: %Data.Worker.Metrics{
             memory: %{available: available, total: total}
           }
         } = _w, latency},
        %Data.FunctionStruct{
          metadata: %Data.FunctionMetadata{
            capacity: function_capacity
          }
        },
        invalidate_capacity,
        invalidate_invocations,
        invalidate_latency
      ) do
    function_capacity <= available and
      (invalidate_invocations == :infinity or c < invalidate_invocations) and
      (invalidate_capacity == :infinity or
         (total - available + function_capacity) / total * 100 <= invalidate_capacity) and
      (invalidate_latency == :infinity or latency <= invalidate_latency)
  end

  @doc """
  Helper function, returns a list of tuples {worker, latency},
  associating each worker with its total computed latency towards the service urls (of a function).
  ## Parameters
  - workers: list of workers with associated metrics (latencies, specifically).
  - urls: a list of strings, containing the urls of all services used by the function.
  - equation: a tuple, produced by Core.Domain.Policies.Support.CappEquations.parse().
              Represents the cost equation associated with the function.
  - unknown_latency: value to be used when a latency cannot be found for a worker.

  ## Returns
  - A list of tuples {worker, latency}, where the workers are in the same order as the ones in input,
    and the latencies are the associated total computed latencies.
  """
  @spec get_worker_latencies([Data.Worker.t()], [String.t()], tuple(), number()) :: [
          {Data.Worker.t(), number()}
        ]
  def get_worker_latencies(workers, urls, equation, unknown_latency \\ @unknown_latency) do
    workers
    |> Enum.map(fn
      # map each worker to a list of latencies towards services
      %Data.Worker{resources: %{latencies: %{} = latencies}} = w ->
        {w, urls |> Enum.map(fn url -> Map.get(latencies, url, unknown_latency) end)}

      %Data.Worker{resources: %{latencies: nil}} = w ->
        {w, urls |> Enum.map(fn _ -> unknown_latency end)}

      %Data.Worker{resources: nil} = w ->
        {w, urls |> Enum.map(fn _ -> unknown_latency end)}
    end)
    |> Enum.map(fn {w, lats} ->
      # map each latency to a variable, identified by a letter
      # i.e "A" => latency at index 0; "B" => latency at index 1; ...
      vars =
        lats
        |> Enum.with_index(0)
        |> Enum.map(fn {latency, index} -> {<<65 + index::utf8>>, latency} end)
        |> Enum.into(%{})

      # map each worker to the total latency towards the services, according to the equation
      {w, CappEquations.evaluate(equation, vars)}
    end)
  end
end

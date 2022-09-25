# Licensed to the Apache Software Foundation (ASF) under one
# or more contributor license agreements.  See the NOTICE file
# distributed with this work for additional information
# regarding copyright ownership.  The ASF licenses this file
# to you under the Apache License, Version 2.0 (the
# "License"); you may not use this file except in compliance
# with the License.  You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing,
# software distributed under the License is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
# KIND, either express or implied.  See the License for the
# specific language governing permissions and limitations
# under the License.
#
defmodule Core.Domain.Scheduler do
  @moduledoc """
  Scheduler for the funless platform. It is used to choose a worker to run a function.
  """

  alias Core.Domain.Ports.Telemetry.Api
  require Logger

  @doc """
  Receives a list of workers and chooses one which can be used for invocation.
  """
  @spec select(list()) :: atom()
  def select([]) do
    Logger.warn("Scheduler: tried selection with NO workers")
    :no_workers
  end

  def select([w]) do
    Logger.info("Scheduler: selection with only one worker #{inspect(w)}")
    w
  end

  def select(workers) do
    Logger.info("Scheduler: selection with #{length(workers)} workers")

    # Get the resources
    resources = Enum.map(workers, &Api.resources/1) |> Enum.filter(&match?({:ok, _}, &1))
    # Couple worker -> {:ok, resources}
    workers_resources = Enum.zip(workers, resources)
    # Get the {worker, {:ok, resources} with the lowest cpu utilization
    Enum.min_by(workers_resources, fn {_w, {:ok, r}} -> r.cpu end)
    |> elem(0)
  end
end

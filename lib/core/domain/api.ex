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

defmodule Core.Domain.Api do
  @moduledoc """
  Provides functions to deal with requests to workers.
  """
  require Logger
  alias Core.Domain.Nodes
  alias Core.Domain.Ports.Commands
  alias Core.Domain.Scheduler

  @type ivk_params :: %{
          namespace: String.t(),
          function: String.t(),
          args: Map.t()
        }

  @spec invoke(ivk_params) :: {:ok, %{:result => String.t()}} | {:error, any}
  @doc """
  Sends an invocation request for the `name` function in the `ns` namespace,
  specified in the invocation parameters.

  The request is sent with the worker adapter to a worker chosen from the `worker_nodes`, if any.

  ## Parameters
    - ivk_params: a map with the function name.
  """
  def invoke(ivk_params) do
    Logger.info("API: received invocation for function '#{ivk_params["function"]}'")

    Scheduler.select(Nodes.worker_nodes())
    |> invoke_on_chosen(ivk_params)
  end

  defp invoke_on_chosen(:no_workers, _) do
    Logger.warn("API: no workers found")
    {:error, :no_workers}
  end

  defp invoke_on_chosen(worker, ivk_params) do
    Logger.info("API: found worker #{worker} for invocation")
    Commands.send_invocation_command(worker, ivk_params)
  end
end

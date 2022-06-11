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
  def parse_invoke_request() do
  end
end

defmodule FnWorker do
  @moduledoc """
  Worker struct to pass to Scheduler. The id field refers to the index in the node list.
  """
  @enforce_keys [:id]
  defstruct [:id]
end

defmodule Core.Domain.Api do
  @moduledoc """
  Provides functions to deal with requests to workers.
  """

  @doc """
  Sends an invocation request
  for the `name` function in the `ns` namespace.

  The request is sent with the given `send_fun` argument
  to a worker chosen from the given `nodes`, if any.

  ## Parameters
    - nodes: List of nodes to evaluate to find a suitable worker for the function.
    - ns: Namespace of the function.
    - name: Name of the function to invoke.
    - send_fun: Send function to use to send invocation request to the worker chosen
      (it should take the worker and the function name as arguments). By default it uses GenServer.call.
  """

  # @spec invoke(List.t(), String.t(), String.t(), Function.t(Atom.t(), String.t())) :: term()
  # def invoke(nodes, ns, name, send_fun \\ &genserver_call/2) do
  #   nodes |> select_worker |> send_invocation(send_fun, ns <> name)
  # end

  @type ivk_params :: %{name: String.t()}

  @spec invoke(ivk_params) :: :ok
  def invoke(ivk_params) do
    IO.inspect(ivk_params)
    :ok
  end

  # def select_worker(nodes) do
  #   Enum.map(nodes, &Atom.to_string(&1))
  #   |> Enum.zip(0..length(nodes))
  #   |> Enum.flat_map(&filter_worker(&1))
  #   |> Scheduler.select()
  #   |> extract_worker(nodes)
  # end

  # defp send_invocation(c = :no_workers, _, _), do: c

  # defp send_invocation(chosen, send_fn, name) do
  #   send_fn.(chosen, name)
  #   chosen
  # end

  # # unidiomatic to use enum.at
  # defp extract_worker(%FnWorker{id: i}, nodes), do: Enum.at(nodes, i)
  # defp extract_worker(_, _), do: :no_workers

  # defp filter_worker(t) do
  #   if String.contains?(elem(t, 0), "worker"), do: [%FnWorker{id: elem(t, 1)}], else: []
  # end

  # defp genserver_call(worker, fn_name) do
  #   GenServer.call(
  #     {:worker, worker},
  #     {:prepare,
  #      %{
  #        # hellojs
  #        name: fn_name,
  #        image: "node:lts-alpine",
  #        main_file: "/opt/index.js",
  #        archive: "js/hello.tar.gz"
  #      }}
  #   )
  # end
end

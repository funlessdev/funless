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

  alias Core.Domain.Nodes

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

  @type ivk_params :: %{:name => String.t()}

  @spec invoke(Struct.t()) :: {:ok, name: String.t()} | {:error, message: String.t()}
  def invoke(ivk_params) do
    Core.Domain.Internal.Invoker.invoke(Nodes.worker_nodes(), ivk_params)
  end
end

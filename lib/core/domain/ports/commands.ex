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
defmodule Core.Domain.Ports.Commands do
  @moduledoc """
  Port for sending commands to workers.
  """
  @type ivk_params :: %{:name => String.t()}
  @type worker :: Atom.t()

  @adapter :core |> Application.compile_env!(__MODULE__) |> Keyword.fetch!(:adapter)

  @callback send_invocation_command(worker, ivk_params) ::
              {:ok, name: String.t()} | {:error, message: String.t()}

  @doc """
  Sends an invocation command to a worker.
  It requires a worker (a fully qualified name of another node with the :worker actor on),
  and invocation parameteres (a map with a "name" key for the function name to invoke).
  """
  defdelegate send_invocation_command(worker, ivk_params), to: @adapter
end

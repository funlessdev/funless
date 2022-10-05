# Copyright 2022 Giuseppe De Palma, Matteo Trentin
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

defmodule Core.Domain.Ports.Commands do
  @moduledoc """
  Port for sending commands to workers.
  """

  alias Core.Domain.IvkResult

  @type worker :: atom()
  @type fl_function :: Core.Domain.FunctionStruct.t()

  @adapter :core |> Application.compile_env!(__MODULE__) |> Keyword.fetch!(:adapter)

  @callback send_invocation_command(worker, fl_function, map()) ::
              {:ok, IvkResult.t()} | {:error, atom}

  @doc """
  Sends an invocation command to a worker.
  It requires a worker (a fully qualified name of another node with the :worker actor on), a function struct and
  (optionally empty) function arguments.
  """
  @spec send_invocation_command(worker, fl_function, map()) ::
          {:ok, IvkResult.t()} | {:error, atom}
  defdelegate send_invocation_command(worker, function, args), to: @adapter
end

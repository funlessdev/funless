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

defmodule Worker.Domain.Ports.WaitForCode do
  @moduledoc """
  Handles invocations where the code was not found. The underlying adapter should implement a GenServer.
  """
  @callback wait_for_code(map()) :: {:ok, pid()} | {:error, any}

  @adapter :worker |> Application.compile_env!(__MODULE__) |> Keyword.fetch!(:adapter)

  @doc """
  Waits for the invocation with code to be sent by the Core. Should spawn a GenServer.
  """
  @spec wait_for_code(map()) :: {:ok, pid()} | {:error, any}
  defdelegate wait_for_code(args), to: @adapter
end

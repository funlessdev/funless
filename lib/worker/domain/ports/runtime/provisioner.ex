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

defmodule Worker.Domain.Ports.Runtime.Provisioner do
  @moduledoc """
  Port for runtime creation.
  """

  alias Worker.Domain.FunctionStruct
  alias Worker.Domain.RuntimeStruct

  @adapter :worker |> Application.compile_env!(__MODULE__) |> Keyword.fetch!(:adapter)

  @callback prepare(FunctionStruct.t(), String.t()) :: {:ok, RuntimeStruct.t()} | {:error, any}

  @doc """
  Creates a runtime for the given function and names it `runtime_name`.

  ### Parameters
    - function: a struct with all the fields required by Worker.Domain.Function
    - runtime_name: the name of the runtime to be prepared

  ### Returns
    - {:ok, runtime} if the runtime is successfully prepared
    - {:error, err} if any error is encountered
  """
  @spec prepare(FunctionStruct.t(), String.t()) :: {:ok, RuntimeStruct.t()} | {:error, any}
  defdelegate prepare(fl_function, runtime_name), to: @adapter
end

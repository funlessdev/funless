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

defmodule Worker.Domain.Ports.Runtime.Runner do
  @moduledoc """
  Port to run functions in runtimes.
  """
  alias Data.ExecutionResource
  alias Data.FunctionStruct

  @adapter :worker |> Application.compile_env!(__MODULE__) |> Keyword.fetch!(:adapter)

  @callback run_function(FunctionStruct.t(), any(), ExecutionResource.t()) ::
              {:ok, any} | {:error, any}

  @doc """
  Runs a function in the given runtime.

  ### Parameters
    - function: a struct with all the fields required by Data.FunctionStruct
    - input: the input to be passed to the function
    - resource: an ExecutionResource.t() required by Worker.Domain.Runtime.Runner

  ### Returns
    - {:ok, output} if the function is successfully executed
    - {:error, err} if any error is encountered
  """
  @spec run_function(FunctionStruct.t(), any(), ExecutionResource.t()) ::
          {:ok, any} | {:error, any}
  defdelegate run_function(fl_function, args, runtime), to: @adapter
end

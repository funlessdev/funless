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

defmodule Worker.Domain.Ports.Runtime do
  @moduledoc """
  Port for runtime manipulation.
  """
  alias Worker.Domain.FunctionStruct
  alias Worker.Domain.RuntimeStruct

  @type worker_function :: FunctionStruct.t()

  @type args :: any()

  @type runtime_name :: String.t()

  @type runtime :: RuntimeStruct.t()

  @callback prepare(worker_function, runtime_name) :: {:ok, runtime} | {:error, any}
  @callback run_function(worker_function, args, runtime) :: {:ok, any} | {:error, any}
  @callback cleanup(runtime) :: {:ok, runtime} | {:error, any}

  @adapter :worker |> Application.compile_env!(__MODULE__) |> Keyword.fetch!(:adapter)

  defdelegate prepare(worker_function, runtime_name), to: @adapter
  defdelegate run_function(worker_function, args, runtime), to: @adapter
  defdelegate cleanup(runtime), to: @adapter
end

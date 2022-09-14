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

defmodule Worker.Domain.Ports.RuntimeTracker do
  @moduledoc """
  Port for keeping track of {function, runtime} tuples in storage.
  """
  alias Worker.Domain.RuntimeStruct

  @type function_name :: String.t()

  @type runtime :: RuntimeStruct.t()

  @callback get_runtimes(function_name) :: [runtime]

  # TODO: the ets tracker never returns an error and there are no error checks in domain
  @callback insert_runtime(function_name, runtime) ::
              {:ok, {function_name, runtime}} | {:error, any}

  @callback delete_runtime(function_name, runtime) ::
              {:ok, {function_name, runtime}} | {:error, any}

  @adapter :worker |> Application.compile_env!(__MODULE__) |> Keyword.fetch!(:adapter)

  defdelegate get_runtimes(function_name), to: @adapter
  defdelegate insert_runtime(function_name, runtime), to: @adapter
  defdelegate delete_runtime(function_name, runtime), to: @adapter
end

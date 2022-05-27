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

defmodule Worker.Domain.Ports.FunctionStorage do
  @moduledoc """
  Port for keeping track of {function, container} tuples in storage.
  """
  @type function_name :: String.t()
  @type container_name :: String.t()

  @callback get_function_containers(function_name) ::
              {:ok, {function_name, [container_name]}} | {:error, any}
  @callback insert_function_container(function_name, container_name) ::
              {:ok, {function_name, container_name}} | {:error, any}
  @callback delete_function_container(function_name, container_name) ::
              {:ok, {function_name, container_name}} | {:error, any}

  # TODO: add dynamic adapter based on env
  @adapter Worker.Adapters.FunctionStorage.ETS
  defdelegate get_function_containers(function_name), to: @adapter
  defdelegate insert_function_container(function_name, container_name), to: @adapter
  defdelegate delete_function_container(function_name, container_name), to: @adapter
end

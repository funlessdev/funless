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

defmodule Worker.Adapters.FunctionStorage.Test do
  @moduledoc false
  @behaviour Worker.Domain.Ports.FunctionStorage

  @impl true
  def get_function_runtimes(function_name) do
    {:ok,
     {function_name,
      [
        %Worker.Domain.Runtime{name: "runtime1", host: "localhost", port: "8080"},
        %Worker.Domain.Runtime{name: "runtime2", host: "localhost", port: "8081"}
      ]}}
  end

  @impl true
  def insert_function_runtime(function_name, runtime) do
    {:ok, {function_name, runtime}}
  end

  @impl true
  def delete_function_runtime(function_name, runtime) do
    {:ok, {function_name, runtime}}
  end
end

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
defmodule Worker.Adapters.Requests.Cluster do
  @moduledoc """

  """
  alias Worker.Domain.Api

  def prepare(function, from) do
    result = Api.prepare_container(function)
    GenServer.reply(from, result)
  end

  def invoke(function, from) do
    result =
      if Api.function_has_container?(function) do
        Api.run_function(function)
      else
        case Api.prepare_container(function) do
          {:ok, _} -> Api.run_function(function)
          {:error, err} -> {:error, err}
        end
      end

    GenServer.reply(from, result)
  end

  def cleanup(function, from) do
    result = Api.cleanup(function)
    GenServer.reply(from, result)
  end
end

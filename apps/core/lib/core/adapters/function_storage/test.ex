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

defmodule Core.Adapters.FunctionStorage.Test do
  @moduledoc false

  alias Core.Domain.FunctionStruct
  @behaviour Core.Domain.Ports.FunctionStorage

  @impl true
  def init_database(_nodes) do
    :ok
  end

  @impl true
  def get_function(function_name, function_namespace) do
    f = %FunctionStruct{
      name: function_name,
      namespace: function_namespace,
      code: "console.log(\"hello\")",
      image: "nodejs"
    }

    {:ok, f}
  end

  @impl true
  def insert_function(%FunctionStruct{name: function_name}) do
    {:ok, function_name}
  end

  @impl true
  def delete_function(function_name, _function_namespace) do
    {:ok, function_name}
  end
end

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
defmodule Core.Domain.Api.Function do
  @moduledoc """
  Provides functions to interact with creation and deletion of FunctionStruct on FunctionStorage.
  """

  require Logger
  alias Core.Domain.FunctionStruct
  alias Core.Domain.Ports.FunctionStorage

  def new(%{"name" => name, "code" => code, "image" => image} = raw_params) do
    function = %FunctionStruct{
      name: name,
      namespace: raw_params["namespace"] || "_",
      image: image,
      code: code
    }

    Logger.info("API: new function request for #{function} in namespace #{function.namespace}")

    res = FunctionStorage.insert_function(function)

    case res do
      {:ok, function_name} -> {:ok, %{result: function_name}}
      err -> err
    end
  end

  def new(_), do: {:error, :bad_params}

  def delete(%{"name" => name, "namespace" => namespace}) do
    Logger.info("API: received deletion request for function #{name} in namespace #{namespace}")
    res = FunctionStorage.delete_function(name, namespace)

    case res do
      {:ok, function_name} -> {:ok, %{result: function_name}}
      err -> err
    end
  end

  def delete(_), do: {:error, :bad_params}
end

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

defmodule Core.Domain.Api.FunctionRepo do
  @moduledoc """
  Provides functions to interact with creation and deletion of FunctionStruct on FunctionStorage.
  """

  require Logger
  alias Core.Domain.FunctionStruct
  alias Core.Domain.Ports.FunctionStorage
  alias Core.Domain.ResultStruct

  @doc """
  Stores a new function in the FunctionStorage.

  ## Parameters
  - `function`: FunctionStruct to be stored.

  ## Returns
  - `{:ok, %{result: function_name}}`: if the function was successfully stored.
  - `{:error, :bad_params}`: if the function is not a valid FunctionStruct.
  - `{:error, {:aborted, reason}}`: if the function could not be stored.
  """
  @spec new(FunctionStruct.t()) ::
          {:ok, ResultStruct.t()} | {:error, :bad_params} | {:error, {:bad_insert, any}}
  def new(%{"name" => name, "code" => code} = raw_params) do
    function = %FunctionStruct{
      name: name,
      namespace: raw_params["namespace"] || "_",
      code: code,
      image: raw_params["image"] || "_"
    }

    Logger.info("API: create request for function #{name} in namespace #{function.namespace}")

    FunctionStorage.insert_function(function)
    |> case do
      {:ok, function_name} ->
        {:ok, %ResultStruct{result: function_name}}

      {:error, {:aborted, reason}} ->
        Logger.error("API: create request for function #{name} failed: #{inspect(reason)}")
        {:error, {:bad_insert, reason}}
    end
  end

  def new(_), do: {:error, :bad_params}

  @doc """
  Deletes a function from the FunctionStorage.

  ## Parameters
  - function: The function struct with the name and namespace of the function to delete.

  ## Returns
  - `{:ok, %{"result" => function_name}}`: if the function was successfully deleted.
  - `{:error, :bad_params}`: if the function is not a valid FunctionStruct.
  - `{:error, {:bad_delete, reason}}`: if the function could not be deleted.
  """
  @spec delete(FunctionStruct.t()) :: {:ok, ResultStruct.t()} | {:error, {:bad_delete, any}}
  def delete(%{"name" => name, "namespace" => namespace}) do
    Logger.info("API: delete request for function #{name} in namespace #{namespace}")
    res = FunctionStorage.delete_function(name, namespace)

    case res do
      {:ok, function_name} ->
        {:ok, %ResultStruct{result: function_name}}

      {:error, {:aborted, reason}} ->
        Logger.error("API: delete request for function #{name} failed: #{inspect(reason)}")
        {:error, {:bad_delete, reason}}
    end
  end

  def delete(_), do: {:error, :bad_params}
end

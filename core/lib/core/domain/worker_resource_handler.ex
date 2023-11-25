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

defmodule Core.Domain.WorkerResourceHandler do
  @moduledoc """
  Provides functions to handle resources on workers.
  """
  alias Core.Domain.Ports.Commands

  @doc """
  Sends a store_function request to the given worker, for the given function.
  The logic is delegated to the Commands adapter.

  ## Parameters
  - `worker`: the worker on which the function will be stored
  - `function`: the function that will be stored

  ## Returns
  - `:ok` if the function was stored successfully
  - `{:error, err}` if any error was raised during the operation
  """
  @spec store_function(atom(), Data.FunctionStruct.t()) :: :ok | {:error, any()}
  def store_function(worker, function) do
    Commands.send_store_function(worker, function)
  end
end

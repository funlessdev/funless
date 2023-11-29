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

defmodule Worker.Domain.Ports.Runtime.Cleaner do
  @moduledoc """
  Port for ExecutionResource removal.
  """
  alias Data.ExecutionResource

  @callback cleanup(ExecutionResource.t()) :: :ok | {:error, any}

  @adapter :worker |> Application.compile_env!(__MODULE__) |> Keyword.fetch!(:adapter)

  @doc """
  Cleans up the resources from the host system associated with a particular function.

  ### Parameters
  - `resource` - The ExecutionResource.t() to be removed.

  ### Returns
  - `:ok` - if removal was successful.
  - `{:error, err}` - An error message if the resources could not be removed.
  """
  @spec cleanup(ExecutionResource.t()) :: :ok | {:error, any}
  defdelegate cleanup(resource), to: @adapter
end

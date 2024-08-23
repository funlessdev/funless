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

defmodule Worker.Domain.Ports.ExternalServiceStorage do
  @moduledoc """
  Port for storing and retrieving node information (e.g. long name, tag).
  """
  @callback get(String.t()) :: {:ok, integer()} | {:error, :not_found} | {:error, any}
  @callback insert(String.t(), integer()) :: :ok | {:error, :exists} | {:error, any}
  @callback update(String.t(), integer()) :: :ok | {:error, :not_found} | {:error, any}
  @callback upsert(String.t(), integer()) :: :ok | {:error, any}
  @callback keys() :: {:ok, list(String.t())} | {:error, any}
  @callback delete(String.t()) :: :ok | {:error, :not_found} | {:error, any}

  @adapter :worker |> Application.compile_env!(__MODULE__) |> Keyword.fetch!(:adapter)

  @doc """
  Retrieve the value associated with the given key.

  ### Parameters
  - `key` - Identifier (e.g. long_name, tag).

  ### Returns
  - `{:ok, value}` - The value for the given key if found.
  - `{:error, :not_found}` - If the key is not found.
  - `{:error, err}` - Any other error, might depend on implementation (e.g. file errors).
  """
  @spec get(String.t()) :: {:ok, integer()} | {:error, :not_found} | {:error, any}
  defdelegate get(key), to: @adapter

  @doc """
  Insert a new value associated with the given key.

  ### Parameters
  - `key` - Identifier (e.g. long_name, tag). Must be a string.
  - `value` - Must be a string.

  ### Returns
  - `:ok` - The value was inserted successfully.
  - `{:error, :exists}` - If the key was already present.
  - `{:error, _}` - Any other error, might depend on implementation (e.g. file errors).
  """
  @spec insert(String.t(), integer()) :: :ok | {:error, :exists} | {:error, any}
  defdelegate insert(key, value), to: @adapter

  @doc """
  Update the value associated with the given (existing) key.

  ### Parameters
  - `key` - Identifier. Must be a string.
  - `value` - Must be an integer.

  ### Returns
  - `:ok` - The value was updated successfully.
  - `{:error, :not_found}` - If the key was not found.
  - `{:error, err}` - Any other error, might depend on implementation (e.g. file errors).
  """
  @spec update(String.t(), integer()) :: :ok | {:error, :not_found} | {:error, any}
  defdelegate update(key, value), to: @adapter

  @doc """
  Insert or update the value associated with the given key.

  ### Parameters
  - `key` - Identifier (e.g. long_name, tag). Must be a string.
  - `value` - Must be an integer.

  ### Returns
  - `:ok` - The value was inserted or updated successfully.
  - `{:error, err}` - Any other error, might depend on implementation (e.g. file errors).
  """
  @spec upsert(String.t(), integer()) :: :ok | {:error, any}
  defdelegate upsert(key, value), to: @adapter

  @spec keys() :: {:error, any()} | {:ok, list()}
  defdelegate keys(), to: @adapter

  @doc """
  Delete both the given key and its associated value.

  ### Parameters
  - `key` - Identifier (e.g. long_name, tag).

  ### Returns
  - `:ok` - The key-value pair was deleted successfully.
  - `{:error, :not_found}` - If the key is not found.
  - `{:error, err}` - Any other error, might depend on implementation (e.g. file errors).
  """
  @spec delete(String.t()) :: :ok | :error
  defdelegate delete(key), to: @adapter
end

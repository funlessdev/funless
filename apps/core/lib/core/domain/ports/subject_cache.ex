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

defmodule Core.Domain.Ports.SubjectCache do
  @moduledoc """
  Port for the SubjectCache behaviour.
  The SubjectCache is a cache that stores the token associated to a subject.
  """

  @callback get(String.t()) :: String.t() | :subject_not_found
  @callback insert(String.t(), String.t()) :: :ok | {:error, any}
  @callback delete(String.t()) :: :ok | {:error, any}

  @adapter :core |> Application.compile_env!(__MODULE__) |> Keyword.fetch!(:adapter)

  @doc """
  """
  @spec get(String.t()) :: String.t() | :subject_not_found
  defdelegate get(subject_name), to: @adapter

  @doc """
  """
  @spec insert(String.t(), String.t()) :: :ok | {:error, any}
  defdelegate insert(subject_name, token), to: @adapter

  @doc """
  """
  @spec delete(String.t()) :: :ok | {:error, any}
  defdelegate delete(subject_name), to: @adapter
end

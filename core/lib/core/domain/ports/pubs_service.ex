# Copyright 2024 Giuseppe De Palma, Matteo Trentin
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

defmodule Core.Domain.Ports.PubsService do
  @moduledoc """
  Port for contacting the service exposing PUBS from the cluster.
  """
  @adapter :core |> Application.compile_env!(__MODULE__) |> Keyword.fetch!(:adapter)
  @callback compute_upper_bound([String.t()]) ::
              {:ok, String.t()} | {:error, any()}
  @callback get_equation(String.t(), String.t()) ::
              {:ok, String.t()} | {:error, any()}

  @doc """
  """
  @spec compute_upper_bound([String.t()]) :: {:ok, String.t()} | {:error, any()}
  defdelegate compute_upper_bound(equations), to: @adapter

  @doc """
  """
  @spec get_equation(String.t(), String.t()) :: {:ok, String.t()} | {:error, any()}
  defdelegate get_equation(name, code), to: @adapter
end

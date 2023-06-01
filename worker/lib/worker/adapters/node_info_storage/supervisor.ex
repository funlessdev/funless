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

defmodule Worker.Adapters.NodeInfoStorage.Supervisor do
  @moduledoc """
  Supervisor for the Cachex Node Info Storage.
  It implements the behaviour of Ports.NodeInfoStorage.Supervisor to define the children to supervise.
  Starts Cachex and runs the initial setup Task.
  """
  alias Worker.Adapters.NodeInfoStorage.LocalInfoStorage

  @behaviour Worker.Domain.Ports.NodeInfoStorage.Supervisor
  @cache :node_info_cache
  @info_path :worker
             |> Application.compile_env!(Worker.Adapters.NodeInfoStorage.LocalInfoStorage)
             |> Keyword.fetch!(:path)

  defp setup do
    case Cachex.load(@cache, @info_path) do
      {:error, _} ->
        long_name = System.get_env("NODE_LONG_NAME", Node.self() |> Atom.to_string())
        tag = System.get_env("NODE_TAG", Node.self() |> Atom.to_string())
        LocalInfoStorage.insert("long_name", long_name)
        LocalInfoStorage.insert("tag", tag)

      {:ok, _} ->
        :ok
    end
  end

  @impl true
  def children do
    [
      {Cachex, name: @cache},
      {Task, &setup/0}
    ]
  end
end

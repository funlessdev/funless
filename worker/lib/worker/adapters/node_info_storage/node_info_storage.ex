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

defmodule Worker.Adapters.NodeInfoStorage do
  @behaviour Worker.Domain.Ports.NodeInfoStorage

  @impl true
  def get(key) do
    {:ok, "TODO"}
  end

  @impl true
  def insert(key, value) do
    :ok
  end

  @impl true
  def update(key, value) do
    :ok
  end

  @impl true
  def delete(key) do
    :ok
  end
end

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

defmodule Core.Adapters.PubsService do
  @moduledoc """
  Contacts the service exposing PUBS in the cluster.
  Assumes a simple API that allows for both upper bound and equation computation.
  """
  @behaviour Core.Domain.Ports.PubsService

  @impl true
  def compute_upper_bound(_equations) do
    {:ok, ""}
  end

  @impl true
  def get_equation(_function_name, _function_code) do
    {:ok, ""}
  end
end

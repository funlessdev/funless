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

defprotocol Core.Domain.Policies.SchedulingPolicy do
  @moduledoc """
    Protocol to define scheduling policies.
    Each policy is parameterized on the type of its configuration.
  """

  @doc """
    Should select a worker from a list of workers, given a specific configuration.
  """
  @spec select(t, [Data.Worker.t()], Data.FunctionStruct.t(), map()) ::
          {:ok, Data.Worker.t()} | {:error, any}
  def select(configuration, workers, function, args)
end

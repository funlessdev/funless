# Licensed to the Apache Software Foundation (ASF) under one
# or more contributor license agreements.  See the NOTICE file
# distributed with this work for additional information
# regarding copyright ownership.  The ASF licenses this file
# to you under the Apache License, Version 2.0 (the
# "License"); you may not use this file except in compliance
# with the License.  You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing,
# software distributed under the License is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
# KIND, either express or implied.  See the License for the
# specific language governing permissions and limitations
# under the License.
#

defmodule Core.Adapters.Telemetry.Native.Api do
  @moduledoc """
  Adapter to request telemetry data about workers.
  """
  @behaviour Core.Domain.Ports.Telemetry.Api

  @impl true
  def resources(worker) do
    res = :ets.lookup(:telemetry_ets_server, worker) |> Enum.map(fn {_w, r} -> r end)

    case res do
      [r | _] -> {:ok, r}
      [] -> {:error, :not_found}
    end
  end
end

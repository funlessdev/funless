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

defmodule Worker.Adapters.Telemetry.Handler do
  @moduledoc """
    Contains functions to monitor telemetry events produced by the worker.
  """

  def setup do
    events = [
      [:worker, :resources]
    ]

    :telemetry.attach_many("worker-telemetry-handler", events, &__MODULE__.handle_event/4, nil)
  end

  def handle_event([:worker, :resources], resources, _metadata, _config) do
    GenServer.call(:telemetry_ets_server, {:insert, :resources, resources})
  end
end

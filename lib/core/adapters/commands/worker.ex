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

defmodule Core.Adapters.Commands.Worker do
  @moduledoc """
  Adapter to send commands to a worker actor.
  Currently implemented commands: invocation.
  """
  require Elixir.Logger

  @behaviour Core.Domain.Ports.Commands

  @impl true
  def send_invocation_command(worker, ivk_params) do
    f_name = ivk_params["name"]
    Elixir.Logger.info("Sending invocation request to worker #{worker} for function #{f_name}")

    reply =
      GenServer.call(
        {:worker, worker},
        {:invoke,
         %{
           name: f_name,
           image: "node:lts-alpine",
           main_file: "/opt/index.js",
           archive: "js/hello.tar.gz"
         }}
      )

    Elixir.Logger.debug(reply)

    {:ok, name: ivk_params["name"]}
  end
end

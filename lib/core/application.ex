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

defmodule Core.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  alias Core.Domain.Nodes
  alias Core.Domain.Ports.FunctionStorage

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      {Bandit, plug: Core.Adapters.Requests.Http.Server, scheme: :http, options: [port: 4001]}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Core.Supervisor]
    Supervisor.start_link(children, opts)
  end

  @impl true
  def start_phase(:init_db, _phase_type, :test) do
    :ok
  end

  @impl true
  def start_phase(:init_db, _phase_type, _env) do
    res =
      Nodes.core_nodes()
      |> FunctionStorage.init_database()

    case res do
      :ok -> :ok
      {:error, {:aborted, {:already_exists, _}}} -> :ok
      err -> err
    end
  end
end

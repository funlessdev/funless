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
defmodule Worker.Adapters.Runtime.OpenWhisk.Nif do
  @moduledoc """
  NIFs used to manipulate docker OpenWhisk runtimes.
  """
  use Rustler, otp_app: :worker, crate: :fn_docker

  #   Creates the `_runtime_name` container, with information taken from `_function`.
  #   ## Parameters
  #     - _function: Worker.Domain.Function struct, containing function information
  #     - _runtime_name: name of the container that will be created
  #     - _network_name: name of the network to which the container will be attached
  #     - _docker_host: path of the docker socket in the current system
  @doc false
  def prepare_runtime(_function, _runtime_name, _network_name, _docker_host) do
    :erlang.nif_error(:nif_not_loaded)
  end

  #   Gets the logs of the `_runtime_name` container.
  #   ## Parameters
  #     - _runtime_name: name of the container
  #     - _docker_host: path of the docker socket in the current system
  @doc false
  def runtime_logs(_runtime_name, _docker_host) do
    :erlang.nif_error(:nif_not_loaded)
  end

  #   Removes the `_runtime_name` container.
  #   ## Parameters
  #     - _runtime_name: name of the container that will be removed
  #     - _docker_host: path of the docker socket in the current system
  @doc false
  def cleanup_runtime(_runtime_name, _docker_host) do
    :erlang.nif_error(:nif_not_loaded)
  end
end

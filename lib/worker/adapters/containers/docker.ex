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

defmodule Worker.Adapters.Containers.Docker do
  @moduledoc """

  """
  @behaviour Worker.Domain.Ports.Containers
  alias Worker.Nif.Fn

  def docker_socket do
    default = "unix:///var/run/docker.sock"
    docker_env = System.get_env("DOCKER_HOST", default)

    case Regex.run(~r/^((unix|tcp):\/\/)(.*)$/, docker_env) do
      nil ->
        default

      [socket | _] ->
        socket
    end
  end

  @impl true
  def prepare_container(worker_function, container_name) do
    Fn.prepare_container(worker_function, container_name, docker_socket())

    receive do
      :ok ->
        {:ok, container_name}

      {:error, err} ->
        {:error, err}
    end
  end

  @impl true
  def run_function(_worker_function, container_name) do
    Fn.run_function(container_name, docker_socket())

    receive do
      {:ok, logs} ->
        {:ok, logs}

      {:error, err} ->
        {:error, err}
    end
  end

  @impl true
  def cleanup(_worker_function, container_name) do
    Fn.cleanup(container_name, docker_socket())

    receive do
      :ok ->
        {:ok, container_name}

      {:error, err} ->
        {:error, err}
    end
  end
end

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
    Docker adapter for container manipulation. The actual docker interaction is done by the Fn NIFs.
  """
  @behaviour Worker.Domain.Ports.Containers
  alias Worker.Nif.Fn

  require Logger

  @doc """
    Checks the DOCKER_HOST environment variable for the docker socket path. If an incorrect path is found, the default is used instead.

    Returns the complete socket path, protocol included.
  """
  def docker_socket do
    default = "unix:///var/run/docker.sock"
    docker_env = System.get_env("DOCKER_HOST", default)

    case Regex.run(~r/^((unix|tcp|http):\/\/)(.*)$/, docker_env) do
      nil ->
        default

      [socket | _] ->
        socket
    end
  end

  @doc """
    Creates a container for the given `worker_function` and names it `container_name`.

    Returns {:ok, container} if no errors are raised;
    returns {:error, err} if any error is raised, forwarding the error message.

    ## Parameters
      - worker_function: Worker.Domain.Function struct, containing the necessary information for the creation of the container
      - container_name: name of the container being created
  """
  @impl true
  def prepare_container(
        worker_function = %Worker.Domain.Function{archive: archive},
        container_name
      ) do
    socket = docker_socket()

    Logger.info("Containers: Creating container for function '#{worker_function.name}'")

    Fn.prepare_container(
      worker_function,
      container_name,
      socket
    )

    receive do
      {:ok, container = %Worker.Domain.Container{host: host, port: port}} ->
        :timer.sleep(1000)
        code = File.read!(archive)

        body =
          Jason.encode!(%{
            "value" => %{"code" => code, "main" => "main", "env" => %{}, "binary" => false}
          })

        request = {"http://#{host}:#{port}/init", [], ["application/json"], body}
        _response = :httpc.request(:post, request, [], [])

        {:ok, container}

      {:error, err} ->
        {:error, err}
    end
  end

  @doc """
    Runs the function wrapped by the `container` container.

    Returns {:ok, results} if the function has been run successfully;
    returns {:error, err} if any error is raised, forwarding the error message.

    ## Parameters
      - _worker_function: Worker.Domain.Function struct; ignored in this function
      - container: struct identifying the container
  """
  @impl true
  def run_function(_worker_function, args, %Worker.Domain.Container{host: host, port: port}) do
    body = Jason.encode!(%{"value" => args})

    request = {"http://#{host}:#{port}/run", [], ["application/json"], body}
    response = :httpc.request(:post, request, [], [])
    response
  end

  @doc """
    Removes the `container` container.

    Returns {:ok, container} if the container is removed successfully;
    returns {:error, err} if any error is raised, forwarding the error message.

    ## Parameters
      - _worker_function: Worker.Domain.Function struct; ignored in this function
      - container: struct identifying the container being removed
  """
  @impl true
  def cleanup(_worker_function, container = %Worker.Domain.Container{name: container_name}) do
    Fn.cleanup(container_name, docker_socket())

    receive do
      :ok ->
        {:ok, container}

      {:error, err} ->
        {:error, err}
    end
  end
end

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

defmodule Worker.Function do
  @moduledoc """
    Function struct, passed to Fn.

    ## Fields
      - name: function name
      - image: base Docker image for the function's container
      - archive: tarball containing the function's code, will be copied into container
      - main_file: path of the function's main file inside the container
  """
  @enforce_keys [:name, :image, :archive]
  defstruct [:name, :image, :archive, :main_file]
end

defmodule Worker.Worker do
  @moduledoc """
    Contains functions used to create, run and remove function containers.
  """
  alias Worker.Fn

  defp get_docker_host() do
    default = "unix:///var/run/docker.sock"
    docker_socket = System.get_env("DOCKER_HOST", default)

    case Regex.run(~r/^((unix|tcp):\/\/)(.*)$/, docker_socket) do
      nil -> default
      [host | _] -> host
    end
  end

  def prepare_container(
        %{name: function_name, image: image_name, archive: archive_name, main_file: main_file},
        from,
        noreply \\ false
      ) do
    docker_host = get_docker_host()
    container_name = function_name <> "-funless-container"

    function = %Worker.Function{
      name: function_name,
      image: image_name,
      archive: archive_name,
      main_file: main_file
    }

    Fn.prepare_container(function, container_name, docker_host)

    receive do
      :ok ->
        GenServer.call(:updater, {:insert, function_name, container_name})

        # prepare_container can also be called as part of the invocation; in this case, we don't need to send a reply after creation (run_function will send it afterwards)
        if !noreply do
          GenServer.reply(from, {:ok, container_name})
        end

        {:ok, container_name}

      {:error, err} ->
        IO.puts("Error while preparing container for function #{function_name}:\n#{err}")
        GenServer.reply(from, {:error, err})
        {:error, err}
    end
  end

  def run_function(%{name: function_name}, from) do
    docker_host = get_docker_host()
    containers = :ets.lookup(:functions_containers, function_name)

    case Enum.fetch(containers, 0) do
      {:ok, {_, container_name}} ->
        Fn.run_function(container_name, docker_host)

        receive do
          {:ok, logs} ->
            IO.puts("Logs from container:\n#{logs}")
            GenServer.reply(from, {:ok, logs})
            {:ok, logs}

          {:error, err} ->
            IO.puts("Error while running function #{function_name}: #{err}")
            GenServer.reply(from, {:error, err})
            {:error, err}
        end

      :error ->
        err = "No container found for function #{function_name}"
        GenServer.reply(from, {:error, err})
        {:error, err}
    end
  end

  def invoke_function(
        %{name: function_name, image: image_name, archive: archive_name, main_file: main_file},
        from
      ) do
    containers = :ets.lookup(:functions_containers, function_name)

    function = %Worker.Function{
      name: function_name,
      image: image_name,
      archive: archive_name,
      main_file: main_file
    }

    # TODO: this check is repeated in run_function, might need refactoring
    case Enum.fetch(containers, 0) do
      {:ok, {_, _}} ->
        run_function(function, from)

      :error ->
        response = prepare_container(function, from, true)

        case response do
          {:ok, _} -> run_function(function, from)
          {:error, err} -> {:error, err}
        end
    end
  end

  def cleanup(%{name: function_name}, from) do
    # TODO: differentiate cleanup all containers from cleanup single container
    docker_host = get_docker_host()
    containers = :ets.lookup(:functions_containers, function_name)

    case Enum.fetch(containers, 0) do
      {:ok, {_, container_name}} ->
        Fn.cleanup(container_name, docker_host)

        receive do
          :ok ->
            GenServer.call(:updater, {:delete, function_name, container_name})
            GenServer.reply(from, {:ok, container_name})
            :ok

          {:error, err} ->
            IO.puts("Error while cleaning up container #{container_name}: #{err}")
            GenServer.reply(from, {:error, err})
            {:error, err}
        end

      :error ->
        err = "No container found for function #{function_name}"
        GenServer.reply(from, {:error, err})
        {:error, err}
    end
  end
end

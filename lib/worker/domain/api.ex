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

defmodule Worker.Domain.Container do
  @moduledoc """
    Container struct, passed to adapters.

    ## Fields
      - name: container name
      - host: container IP address
      - port: container port
  """
  @type t :: %__MODULE__{
          name: String.t(),
          host: String.t(),
          port: String.t()
        }
  @enforce_keys [:name]
  defstruct [:name, :host, :port]
end

defmodule Worker.Domain.Function do
  # TODO: might need different fields (distinguish between single code file and archive; main_file should be main_function)

  @moduledoc """
    Function struct, passed to adapters.

    ## Fields
      - name: function name
      - image: base Docker image for the function's container
      - archive: path of the tarball containing the function's code, will be copied into container
      - main_file: path of the function's main file inside the container
  """
  @type t :: %__MODULE__{
          name: String.t(),
          image: String.t(),
          archive: String.t(),
          main_file: String.t()
        }
  @enforce_keys [:name, :image, :archive, :main_file]
  defstruct [:name, :image, :archive, :main_file]
end

defmodule Worker.Domain.Api do
  @moduledoc """
  Contains functions used to create, run and remove function containers. Side effects (e.g. docker interaction) are delegated to the functions passed as arguments.
  """
  alias Worker.Domain.Ports.Containers
  alias Worker.Domain.Ports.FunctionStorage

  @doc """
    Checks if the function with the given `function_name` has an associated container in the underlying function storage.

    Returns true if containers are found, false otherwise.

    ## Parameters
      - %{name: function_name}: generic struct with a `name` field, containing the function name
  """
  @spec function_has_container?(Struct.t()) :: Boolean.t()
  def function_has_container?(%{
        name: function_name
      }) do
    case FunctionStorage.get_function_containers(function_name) do
      {:ok, _} -> true
      {:error, _} -> false
    end
  end

  @doc """
    Creates a container for the given function; in case of successful creation, the {function, container} couple is inserted in the function storage.

    Returns {:ok, container} if the container is created, otherwise forwards {:error, err} from the Containers implementation.

    ## Parameters
      - %{...}: generic struct with all the fields required by Worker.Domain.Function
  """
  @spec prepare_container(Struct.t()) :: {:ok, String.t()} | {:error, any}
  def prepare_container(%{
        name: function_name,
        image: image_name,
        archive: archive_name,
        main_file: main_file
      }) do
    container_name = function_name <> "-funless-container"

    function = %Worker.Domain.Function{
      name: function_name,
      image: image_name,
      archive: archive_name,
      main_file: main_file
    }

    result = Containers.prepare_container(function, container_name)

    case result do
      {:ok, container = %Worker.Domain.Container{name: container_name}} ->
        FunctionStorage.insert_function_container(function_name, container)
        {:ok, container_name}

      _ ->
        result
    end
  end

  @doc """
    Runs the given function if an associated container exists, using the FunctionStorage and Containers callbacks.

    Returns {:ok, result} if a container exists and the function runs successfully;
    returns {:error, {:nocontainer, err}} if no container is found;
    returns {:error, err} if a container is found, but an error is encountered when running the function.


    ## Parameters
      - %{...}: generic struct with all the fields required by Worker.Domain.Function
      - args: arguments passed to the function
  """
  @spec run_function(Struct.t()) :: {:ok, any} | {:error, any}
  def run_function(
        %{
          name: function_name,
          image: image_name,
          archive: archive_name,
          main_file: main_file
        },
        args \\ %{}
      ) do
    function = %Worker.Domain.Function{
      name: function_name,
      image: image_name,
      archive: archive_name,
      main_file: main_file
    }

    containers = FunctionStorage.get_function_containers(function_name)

    case containers do
      {:ok, {_, [container | _]}} ->
        Containers.run_function(function, args, container)

      {:error, err} ->
        {:error, {:nocontainer, err}}
    end
  end

  @doc """
    Removes the first container associated with the given function.

    Returns {:ok, container} if the cleanup is successful;
    returns {:error, err} if any error is encountered (both while removing the container and when searching for it).

    ## Parameters
      - %{...}: generic struct with all the fields required by Worker.Domain.Function
  """
  @spec cleanup(Struct.t()) :: {:ok, String.t()} | {:error, any}
  def cleanup(%{
        name: function_name,
        image: image_name,
        archive: archive_name,
        main_file: main_file
      }) do
    function = %Worker.Domain.Function{
      name: function_name,
      image: image_name,
      archive: archive_name,
      main_file: main_file
    }

    containers = FunctionStorage.get_function_containers(function_name)

    result =
      case containers do
        {:ok, {_, [container | _]}} ->
          Containers.cleanup(function, container)

        {:error, err} ->
          {:error, err}
      end

    case result do
      {:ok, container = %Worker.Domain.Container{name: container_name}} ->
        FunctionStorage.delete_function_container(function_name, container)
        {:ok, container_name}

      _ ->
        result
    end
  end
end

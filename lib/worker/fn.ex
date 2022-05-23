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

defmodule Worker.Fn do
  @moduledoc "Interface of the Rust Worker functions"
  use Rustler, otp_app: :worker, crate: :fn

  @doc """
    Creates the `_container_name` container, with information taken from `_function`.

    ## Parameters
      - _function: Worker.Function struct, containing function information
      - _container_name: name of the container that will be created
      - _docker_host: path of the docker socket in the current system


    ## Example

    Fn.prepare_container(%Worker.Function{name: "hellojs", image: "node:lts-alpine", archive: "js/hello.tar.gz", main_file: "/opt/index.js"},
          "hello-container",
          "/var/run/docker.sock")
  """
  def prepare_container(_function, _container_name, _docker_host) do
    :erlang.nif_error(:nif_not_loaded)
  end

  @doc """
    Runs the function wrapped by the `_container_name` container.

    ## Parameters
      - _container_name: name of the container that will be used to run the function
      - _docker_host: path of the docker socket in the current system
  """
  def run_function(_container_name, _docker_host) do
    :erlang.nif_error(:nif_not_loaded)
  end

  @doc """
    Removes the `_container_name` container.

    ## Parameters
      - _container_name: name of the container that will be removed
      - _docker_host: path of the docker socket in the current system
  """
  def cleanup(_container_name, _docker_host) do
    :erlang.nif_error(:nif_not_loaded)
  end
end

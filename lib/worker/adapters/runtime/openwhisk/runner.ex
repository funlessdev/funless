# Copyright 2022 Giuseppe De Palma, Matteo Trentin
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

defmodule Worker.Adapters.Runtime.OpenWhisk.Runner do
  @moduledoc """
    Adapter to invoke functions on OpenWhisk Runtimes.
  """
  @behaviour Worker.Domain.Ports.Runtime.Runner

  require Logger

  @impl true
  def run_function(_fl_function, args, runtime) do
    Logger.info("OpenWhisk: Running function on runtime '#{runtime.name}'")
    body = Jason.encode!(%{"value" => args})

    request = {"http://#{runtime.host}:#{runtime.port}/run", [], ["application/json"], body}
    response = :httpc.request(:post, request, [], [])

    case response do
      {:ok, {_, _, payload}} ->
        Logger.info("OpenWhisk: Function executed successfully")
        {:ok, Jason.decode!(payload)}

      {:error, err} ->
        Logger.error("OpenWhisk: Error while running function: #{inspect(err)}")
        {:error, err}
    end
  end
end

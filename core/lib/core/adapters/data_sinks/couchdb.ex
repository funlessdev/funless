# Copyright 2023 Giuseppe De Palma, Matteo Trentin
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

defmodule Core.Adapters.DataSinks.CouchDB do
  @moduledoc """
  CouchDB Data Sink. It writes the results of a function to a CouchDB database via a POST http request.
  """
  use GenServer

  require Logger

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts)
  end

  @impl true
  def init(%{
        "url" => url,
        "username" => username,
        "password" => password
      }) do
    {:ok, %{url: url, username: username, password: password}}
  end

  def init(opts) do
    {:stop,
     "CouchDB sink init failed: expected url to the db, username and password. Received: #{inspect(opts)}"}
  end

  @impl true
  def handle_cast({:save, result}, %{url: url, username: user, password: pass} = state) do
    case Jason.encode(result) do
      {:ok, json} ->
        Logger.debug("CouchDB Sink: sending post request to #{url} to save #{inspect(result)}")
        # httpc post request with the authorization header
        response =
          :httpc.request(
            :post,
            {url,
             [{~c"Authorization", ~c"Basic " ++ :base64.encode_to_string(~c"#{user}:#{pass}")}],
             ~c"application/json", json},
            [],
            []
          )

        Logger.debug("CouchDB Sink: response: #{inspect(response)}")

      {:error, reason} ->
        Logger.warning("CouchDB Sink: failed to encode result into JSON: #{reason}")
    end

    {:noreply, state}
  end
end

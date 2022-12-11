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

defmodule Core.Adapters.Connectors.EventConnectors.Mqtt do
  use GenServer
  require Logger

  def start_link(params) do
    GenServer.start_link(__MODULE__, params)
  end

  def init(%{function: _function, module: _module, params: %{host: _host, port: _port} = params}) do
    Logger.info("MQTT Event Connector: started with params #{inspect(params)}")
    {:ok, params}
  end

  def handle_call(:any, _from, params) do
    {:reply, :ok, params}
  end
end

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

defmodule Worker.Adapters.Runtime.OpenWhisk.Cleaner do
  @moduledoc """
    Docker adapter for OpenWhisk Runtime removal.
    The actual docker interaction is done by the Fn NIFs.
  """
  @behaviour Worker.Domain.Ports.Runtime.Cleaner

  alias Worker.Adapters.Runtime.OpenWhisk.Nif

  require Logger

  @impl true
  def cleanup(runtime) do
    {:ok, socket} = Application.fetch_env(:worker, :docker_host)

    Logger.info("OpenWhisk: Removing runtime '#{runtime.name}'")
    Nif.cleanup_runtime(runtime.name, socket)

    receive do
      :ok ->
        Logger.info("OpenWhisk: Runtime #{inspect(runtime)} removed")
        :ok

      {:error, err} ->
        Logger.error("OpenWhisk: Error removing runtime #{inspect(runtime)}: #{inspect(err)}")
        {:error, err}
    end
  end
end

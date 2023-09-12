# Copyright 2023 Giuseppe De Palma, Matteo Trentin
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

defmodule Worker.Adapters.WaitForCode.Handler do
  @moduledoc """
  Implements GenServer behaviour. Waits for the missing code of functions after
  a previous attempt at invocation.
  """
  alias Data.FunctionStruct
  alias Worker.Domain.InvokeFunction
  use GenServer
  require Logger

  def start_link(args) do
    GenServer.start_link(__MODULE__, args)
  end

  @impl true
  def init(args) do
    Logger.info("Starting GenServer waiting for code")
    {:ok, %{ivk_args: args}}
  end

  @impl true
  def handle_call({:invoke, %FunctionStruct{code: _} = function}, _from, %{ivk_args: args}) do
    {:stop, :normal, InvokeFunction.invoke(function, args), %{}}
  end
end

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

defmodule Worker.Adapters.Runtime.Wasm.Engine do
  @moduledoc """
  The Engine handle for the wasmtime Engine struct.
  It is stored in an Agent so that it can be accessed from different processes.
  """
  use Agent

  @doc """
  Starts the Agent, which will create the Engine and store it in its state.
  The Agent is registered under its module name so that it can be easily accessed from other modules.

  There should be only one Engine per worker deployment.
  """
  def start_link(_opts) do
    # These option could be passed as opts to start_link to customize the engine.
    fuel = false
    opt_level = :speed_and_size
    backtrace = false
    Agent.start_link(fn -> start_engine(fuel, opt_level, backtrace) end, name: __MODULE__)
  end

  @doc """
  Returns the Engine handle stored in the Agent.
  """
  def get_handle() do
    Agent.get(__MODULE__, & &1)
  end

  defp start_engine(fuel, opt_level, backtrace) do
    config =
      %Wasmex.EngineConfig{}
      |> Wasmex.EngineConfig.consume_fuel(fuel)
      |> Wasmex.EngineConfig.cranelift_opt_level(opt_level)
      |> Wasmex.EngineConfig.wasm_backtrace_details(backtrace)

    {:ok, engine} = Wasmex.Engine.new(config)
    engine
  end
end

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

defmodule Core.Integration.Connectors.ManagerTest do
  use ExUnit.Case

  @moduletag integration_test: true

  @main_supervisor Core.Adapters.Connectors.DynamicSupervisor
  @registry Core.Adapters.Connectors.Registry

  alias Core.Adapters.Connectors.Test
  alias Core.Domain.Ports.Connectors.Manager
  alias Data.ConnectedEvent

  # we test all actual functions of the Adapter, except for which_connector,
  # which we mock to avoid the need for external event sources
  describe "manager" do
    setup _ do
      Core.Connectors.Manager.Mock
      |> Mox.stub_with(Core.Adapters.Connectors.Manager)

      Core.Connectors.Manager.Mock
      |> Mox.stub(:which_connector, &Test.which_connector/1)

      event = %ConnectedEvent{
        type: "mqtt",
        params: %{}
      }

      func = %{name: "hello", module: "_"}
      %{func: func, event: event, supervisor: "#{Atom.to_string(@main_supervisor)}._/hello"}
    end

    test "connect/2 should spawn a DynamicSupervisor for the given function and add it to the registry",
         %{func: func, event: event, supervisor: supervisor} do
      result = Manager.connect(func, event)

      assert :ok = result
      assert [{supervisor_pid, _}] = Registry.lookup(@registry, supervisor)
      assert is_pid(supervisor_pid)
    end

    test "connect/2 should spawn a process under the correct supervisor when a function is connected to an event",
         %{func: func, event: event, supervisor: supervisor} do
      Manager.connect(func, event)
      [{supervisor_pid, _}] = Registry.lookup(@registry, supervisor)

      assert [{_, p1, _, _}, {_, p2, _, _}] = DynamicSupervisor.which_children(supervisor_pid)

      assert is_pid(p1)
      assert is_pid(p2)
      assert Process.alive?(p1)
      assert Process.alive?(p2)
    end

    test "disconnect/1 should return :ok and stop the associated supervisor and processes when a function is disconnected from all events",
         %{func: func, supervisor: supervisor} do
      [{supervisor_pid, _}] = Registry.lookup(@registry, supervisor)
      [{_, p1, _, _}, {_, p2, _, _}] = DynamicSupervisor.which_children(supervisor_pid)

      assert :ok = Manager.disconnect(func)

      # given the async nature of the registry, stopped instances might still be registered;
      # we simply test that the processes has stopped
      assert !Process.alive?(supervisor_pid)
      assert !Process.alive?(p1)
      assert !Process.alive?(p2)
    end

    test "disconnect/1 should return {:error, :not_found} when trying to disconnect a function with no associated events",
         %{func: func} do
      result = Manager.disconnect(func)
      assert {:error, :not_found} == result
    end
  end
end

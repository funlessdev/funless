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

  alias Core.Adapters.Connectors.Manager
  alias Core.Adapters.Connectors.ManagerStore
  alias Data.ConnectedEvent

  describe "manager" do
    test "connect/2 should return :ok when a function is connected to an event" do
      event = %ConnectedEvent{type: "mqtt", params: %{host: "localhost", port: "9999"}}
      func = %{name: "hello", module: "_"}
      result = Manager.connect(func, event)
      assert :ok = result
    end

    test "connect/2 should correctly store the pid when a function is connected to an event" do
      event = %ConnectedEvent{type: "mqtt", params: %{host: "localhost", port: "9998"}}
      func = %{name: "hello", module: "_"}
      Manager.connect(func, event)
      result = ManagerStore.get(func.name, func.module)
      assert [pid1, pid2] = result
      assert is_pid(pid1)
      assert is_pid(pid2)
    end

    test "disconnect/1 should return :ok and remove the associated pids from the store when a function is disconnected from all events" do
      func = %{name: "hello", module: "_"}
      r1 = Manager.disconnect(func)
      r2 = ManagerStore.get(func.name, func.module)
      assert :ok == r1
      assert :not_found = r2
    end

    test "disconnect/1 should return {:error, :not_found} when trying to disconnect a function with no associated events" do
      func = %{name: "hello", module: "_"}
      result = Manager.disconnect(func)
      assert {:error, :not_found} == result
    end
  end

  describe "processes" do
    test "connect/2 should correctly spawn a process when a function is connected to an event" do
      e1 = %ConnectedEvent{type: "mqtt", params: %{host: "localhost", port: "9999"}}
      e2 = %ConnectedEvent{type: "mqtt", params: %{host: "localhost", port: "9998"}}
      e3 = %ConnectedEvent{type: "mqtt", params: %{host: "localhost", port: "9997"}}
      func = %{name: "hello", module: "_"}
      Manager.connect(func, e1)
      Manager.connect(func, e2)
      Manager.connect(func, e3)
      [p1, p2, p3] = ManagerStore.get(func.name, func.module)

      assert is_pid(p1)
      assert is_pid(p2)
      assert is_pid(p3)

      assert Process.alive?(p1)
      assert Process.alive?(p2)
      assert Process.alive?(p3)
    end

    test "disconnect/1 should correctly terminate the associated processes when called" do
      func = %{name: "hello", module: "_"}
      [p1, p2, p3] = ManagerStore.get(func.name, func.module)

      Manager.disconnect(func)

      assert !Process.alive?(p1)
      assert !Process.alive?(p2)
      assert !Process.alive?(p3)
    end
  end
end

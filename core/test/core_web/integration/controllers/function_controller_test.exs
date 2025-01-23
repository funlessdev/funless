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

defmodule CoreWeb.FunctionControllerTest do
  use CoreWeb.ConnCase

  require Logger
  import Core.{FunctionsFixtures, FunctionsMetadataFixtures, ModulesFixtures}

  alias Core.Domain.Subjects
  alias Core.Schemas.Function

  @create_attrs %{
    code: %Plug.Upload{path: "#{__DIR__}/../../../support/fixtures/test_code.txt"},
    name: "some_name"
  }
  @create_attrs_events @create_attrs
                       |> Map.put(
                         :events,
                         "[{\"type\": \"mqtt\", \"params\": {}}, {\"type\": \"rabbitmq\", \"params\": {}}, {\"type\": \"rabbitmq\",\"params\": {}}]"
                       )

  @create_attrs_sinks @create_attrs
                      |> Map.put(
                        :sinks,
                        "[{\"type\": \"mongodb\", \"params\": {}}, {\"type\": \"another_one\", \"params\": {}}]"
                      )

  @create_attrs_events_sinks @create_attrs_events |> Map.merge(@create_attrs_sinks)

  @create_attrs_metadata @create_attrs
                         |> Map.put(
                           :metadata,
                           "{\"tag\": \"some_tag\", \"capacity\": 128}"
                         )

  @create_attrs_wait_for_workers @create_attrs |> Map.put(:wait_for_workers, true)
  @create_attrs_no_wait_for_workers @create_attrs |> Map.put(:wait_for_workers, false)

  @update_attrs %{
    code: %Plug.Upload{path: "#{__DIR__}/../../../support/fixtures/test_code.txt"},
    name: "some_updated_name"
  }

  @update_attrs_events @update_attrs
                       |> Map.put(
                         :events,
                         "[{\"type\": \"mqtt\", \"params\": {}}, {\"type\": \"rabbitmq\", \"params\": {}}, {\"type\": \"rabbitmq\",\"params\": {}}]"
                       )

  @update_attrs_sinks @update_attrs
                      |> Map.put(
                        :sinks,
                        "[{\"type\": \"mongodb\", \"params\": {}}, {\"type\": \"another_one\", \"params\": {}}]"
                      )

  @update_attrs_events_sinks @update_attrs_events |> Map.merge(@update_attrs_sinks)

  @invalid_attrs %{code: nil, name: nil}

  setup :set_mox_from_context

  setup %{conn: conn} do
    Core.Commands.Mock |> Mox.stub_with(Core.Adapters.Commands.Test)
    Core.Cluster.Mock |> Mox.stub_with(Core.Adapters.Cluster.Test)
    Core.Connectors.Manager.Mock |> Mox.stub_with(Core.Adapters.Connectors.Test)
    Core.DataSinks.Manager.Mock |> Mox.stub_with(Core.Adapters.DataSinks.Test)
    Core.Telemetry.Metrics.Mock |> Mox.stub_with(Core.Adapters.Telemetry.Test)

    user = Subjects.get_subject_by_name("guest")

    conn =
      conn
      |> put_req_header("accept", "application/json")
      |> put_req_header("authorization", "Bearer #{user.token}")

    {:ok, conn: conn}
  end

  describe "create function" do
    test "renders function when data without events/sinks is valid", %{conn: conn} do
      module = module_fixture()
      conn = post(conn, ~p"/v1/fn/#{module.name}", @create_attrs)
      assert %{"name" => name} = json_response(conn, 201)["data"]

      conn = get(conn, ~p"/v1/fn/#{module.name}/#{name}")
      assert %{"name" => "some_name"} = json_response(conn, 200)["data"]
    end

    test "renders function when data with events is valid", %{conn: conn} do
      module = module_fixture()

      conn = post(conn, ~p"/v1/fn/#{module.name}", @create_attrs_events)
      assert %{"name" => name} = json_response(conn, 201)["data"]

      conn = get(conn, ~p"/v1/fn/#{module.name}/#{name}")
      assert %{"name" => "some_name"} = json_response(conn, 200)["data"]
    end

    test "renders function when data with sinks is valid", %{conn: conn} do
      module = module_fixture()

      conn = post(conn, ~p"/v1/fn/#{module.name}", @create_attrs_sinks)
      assert %{"name" => name} = json_response(conn, 201)["data"]

      conn = get(conn, ~p"/v1/fn/#{module.name}/#{name}")
      assert %{"name" => "some_name"} = json_response(conn, 200)["data"]
    end

    test "renders function when data with metadata is valid", %{conn: conn} do
      module = module_fixture()
      conn = post(conn, ~p"/v1/fn/#{module.name}", @create_attrs_metadata)
      assert %{"name" => name} = json_response(conn, 201)["data"]

      conn = get(conn, ~p"/v1/fn/#{module.name}/#{name}")
      assert %{"name" => "some_name"} = json_response(conn, 200)["data"]
    end

    test "renders function, sends code and waits for it to be sent when wait_for_workers is true",
         %{conn: conn} do
      # TODO
      module = module_fixture()

      Core.Cluster.Mock
      |> Mox.expect(:all_nodes, fn ->
        [:worker1@localhost, :worker2@localhost, :worker3@localhost]
      end)

      Core.Commands.Mock |> Mox.expect(:send_store_function, 3, fn _, _ -> :timer.sleep(1500) end)

      {elapsed, conn} =
        :timer.tc(fn -> post(conn, ~p"/v1/fn/#{module.name}", @create_attrs_wait_for_workers) end)

      assert elapsed >= 1500 * 1000

      assert %{"name" => name} = json_response(conn, 201)["data"]

      conn = get(conn, ~p"/v1/fn/#{module.name}/#{name}")
      assert %{"name" => "some_name"} = json_response(conn, 200)["data"]
    end

    test "renders function, sends code and doesn't wait when wait_for_workers is false", %{
      conn: conn
    } do
      # TODO
      module = module_fixture()

      Core.Cluster.Mock
      |> Mox.expect(:all_nodes, fn ->
        [:worker1@localhost, :worker2@localhost, :worker3@localhost]
      end)

      Core.Commands.Mock |> Mox.expect(:send_store_function, 3, fn _, _ -> :timer.sleep(1500) end)

      task =
        Task.async(fn ->
          post(conn, ~p"/v1/fn/#{module.name}", @create_attrs_no_wait_for_workers)
        end)

      conn = Task.await(task, 500)

      assert %{"name" => name} = json_response(conn, 201)["data"]

      conn = get(conn, ~p"/v1/fn/#{module.name}/#{name}")
      assert %{"name" => "some_name"} = json_response(conn, 200)["data"]
    end

    test "renders function and doesn't send code when store_on_create env is false", %{conn: conn} do
      module = module_fixture()

      Core.Cluster.Mock |> Mox.expect(:all_nodes, 0, fn -> [] end)
      Core.Commands.Mock |> Mox.expect(:send_store_function, 0, fn _, _ -> :ok end)

      store_on_create_old =
        :core
        |> Application.fetch_env!(:store_on_create)

      Application.put_env(:core, :store_on_create, "false")

      conn = post(conn, ~p"/v1/fn/#{module.name}", @create_attrs_wait_for_workers)
      assert %{"name" => name} = json_response(conn, 201)["data"]
      conn = get(conn, ~p"/v1/fn/#{module.name}/#{name}")
      assert %{"name" => "some_name"} = json_response(conn, 200)["data"]

      Application.put_env(:core, :store_on_create, store_on_create_old)
    end

    test "renders errors when data is invalid", %{conn: conn} do
      module = module_fixture()

      conn = post(conn, ~p"/v1/fn/#{module.name}", @invalid_attrs)

      assert json_response(conn, 400)["errors"] != %{}
    end

    test "renders mixed response when some events couldn't connect", %{conn: conn} do
      module = module_fixture()

      Core.Connectors.Manager.Mock
      |> Mox.expect(:connect, 1, fn _, %Data.ConnectedEvent{type: "mqtt"} -> :ok end)

      Core.Connectors.Manager.Mock
      |> Mox.expect(:connect, 2, fn _, %Data.ConnectedEvent{type: "rabbitmq"} ->
        {:error, :some_error}
      end)

      conn = post(conn, ~p"/v1/fn/#{module.name}", @create_attrs_events)

      assert %{
               "name" => _name,
               "events" => [
                 %{"status" => "success"},
                 %{"status" => "error"},
                 %{"status" => "error"}
               ],
               "events_metadata" => %{"successful" => 1, "failed" => 2}
             } = json_response(conn, 207)["data"]
    end

    test "renders mixed response when some sinks couldn't connect", %{conn: conn} do
      module = module_fixture()

      Core.DataSinks.Manager.Mock
      |> Mox.expect(:plug, fn _, %Data.DataSink{type: "mongodb"} -> :ok end)

      Core.DataSinks.Manager.Mock
      |> Mox.expect(:plug, fn _, %Data.DataSink{type: "another_one"} ->
        {:error, :some_error}
      end)

      conn = post(conn, ~p"/v1/fn/#{module.name}", @create_attrs_sinks)

      assert %{
               "name" => _name,
               "sinks" => [
                 %{"status" => "success"},
                 %{"status" => "error"}
               ],
               "sinks_metadata" => %{"successful" => 1, "failed" => 1}
             } = json_response(conn, 207)["data"]
    end

    test "renders mixed response with both events and sinks", %{conn: conn} do
      module = module_fixture()

      Core.Connectors.Manager.Mock
      |> Mox.expect(:connect, 1, fn _, %Data.ConnectedEvent{type: "mqtt"} -> :ok end)

      Core.Connectors.Manager.Mock
      |> Mox.expect(:connect, 2, fn _, %Data.ConnectedEvent{type: "rabbitmq"} ->
        {:error, :some_error}
      end)

      Core.DataSinks.Manager.Mock
      |> Mox.expect(:plug, fn _, %Data.DataSink{type: "mongodb"} -> :ok end)

      Core.DataSinks.Manager.Mock
      |> Mox.expect(:plug, fn _, %Data.DataSink{type: "another_one"} ->
        {:error, :some_error}
      end)

      conn = post(conn, ~p"/v1/fn/#{module.name}", @create_attrs_events_sinks)

      assert %{
               "name" => _name,
               "events" => [
                 %{"status" => "success"},
                 %{"status" => "error"},
                 %{"status" => "error"}
               ],
               "events_metadata" => %{"successful" => 1, "failed" => 2},
               "sinks" => [
                 %{"status" => "success"},
                 %{"status" => "error"}
               ],
               "sinks_metadata" => %{"successful" => 1, "failed" => 1}
             } = json_response(conn, 207)["data"]
    end

    test "error when module doesn't exist", %{conn: conn} do
      conn = post(conn, ~p"/v1/fn/non_existing_module", @create_attrs)
      assert json_response(conn, 404)["errors"] == %{"detail" => "Not Found"}
    end

    test "error when creating already existing function", %{conn: conn} do
      module = module_fixture()
      conn = post(conn, ~p"/v1/fn/#{module.name}", @create_attrs)
      assert json_response(conn, 201)["data"] == %{"name" => "some_name"}

      conn = post(conn, ~p"/v1/fn/#{module.name}", @create_attrs)
      assert json_response(conn, 409)["errors"] == %{"detail" => "Conflict"}
    end
  end

  describe "update function" do
    setup [:create_function]

    test "renders function when data is valid", %{
      conn: conn,
      function: %Function{name: function_name},
      module_name: module_name
    } do
      conn = put(conn, ~p"/v1/fn/#{module_name}/#{function_name}", @update_attrs)

      assert %{"name" => new_name} = json_response(conn, 200)["data"]
      assert new_name == @update_attrs.name

      conn = get(conn, ~p"/v1/fn/#{module_name}/#{new_name}")
      assert %{"name" => ^new_name} = json_response(conn, 200)["data"]
    end

    test "renders errors when data is invalid", %{
      conn: conn,
      function: %Function{name: name},
      module_name: module_name
    } do
      conn = put(conn, ~p"/v1/fn/#{module_name}/#{name}", @invalid_attrs)

      assert json_response(conn, 400)["errors"] != %{}
    end

    test "renders mixed response when some events couldn't connect", %{
      conn: conn,
      function: %Function{name: name},
      module_name: module_name
    } do
      Core.Connectors.Manager.Mock
      |> Mox.expect(:connect, 1, fn _, %Data.ConnectedEvent{type: "mqtt"} -> :ok end)

      Core.Connectors.Manager.Mock
      |> Mox.expect(:connect, 2, fn _, %Data.ConnectedEvent{type: "rabbitmq"} ->
        {:error, :some_error}
      end)

      conn = put(conn, ~p"/v1/fn/#{module_name}/#{name}", @update_attrs_events)

      assert %{
               "name" => _name,
               "events" => [
                 %{"status" => "success"},
                 %{"status" => "error"},
                 %{"status" => "error"}
               ],
               "events_metadata" => %{"successful" => 1, "failed" => 2}
             } = json_response(conn, 207)["data"]
    end

    test "renders mixed response when some sinks couldn't connect", %{
      conn: conn,
      function: %Function{name: name},
      module_name: module_name
    } do
      Core.DataSinks.Manager.Mock
      |> Mox.expect(:plug, fn _, %Data.DataSink{type: "mongodb"} -> :ok end)

      Core.DataSinks.Manager.Mock
      |> Mox.expect(:plug, fn _, %Data.DataSink{type: "another_one"} ->
        {:error, :some_error}
      end)

      conn = put(conn, ~p"/v1/fn/#{module_name}/#{name}", @update_attrs_sinks)

      assert %{
               "name" => _name,
               "sinks" => [
                 %{"status" => "success"},
                 %{"status" => "error"}
               ],
               "sinks_metadata" => %{"successful" => 1, "failed" => 1}
             } = json_response(conn, 207)["data"]
    end

    test "renders mixed response with both events and sinks", %{
      conn: conn,
      function: %Function{name: name},
      module_name: module_name
    } do
      Core.Connectors.Manager.Mock
      |> Mox.expect(:connect, 1, fn _, %Data.ConnectedEvent{type: "mqtt"} -> :ok end)

      Core.Connectors.Manager.Mock
      |> Mox.expect(:connect, 2, fn _, %Data.ConnectedEvent{type: "rabbitmq"} ->
        {:error, :some_error}
      end)

      Core.DataSinks.Manager.Mock
      |> Mox.expect(:plug, fn _, %Data.DataSink{type: "mongodb"} -> :ok end)

      Core.DataSinks.Manager.Mock
      |> Mox.expect(:plug, fn _, %Data.DataSink{type: "another_one"} ->
        {:error, :some_error}
      end)

      conn =
        put(
          conn,
          ~p"/v1/fn/#{module_name}/#{name}",
          @update_attrs_events_sinks
        )

      assert %{
               "name" => _name,
               "events" => [
                 %{"status" => "success"},
                 %{"status" => "error"},
                 %{"status" => "error"}
               ],
               "events_metadata" => %{"successful" => 1, "failed" => 2},
               "sinks" => [
                 %{"status" => "success"},
                 %{"status" => "error"}
               ],
               "sinks_metadata" => %{"successful" => 1, "failed" => 1}
             } = json_response(conn, 207)["data"]
    end
  end

  describe "delete function" do
    setup [:create_function]

    test "deletes chosen function", %{
      conn: conn,
      function: %Function{name: function_name},
      module_name: module_name
    } do
      conn = delete(conn, ~p"/v1/fn/#{module_name}/#{function_name}")
      assert response(conn, 204)

      conn = get(conn, ~p"/v1/fn/#{module_name}/#{function_name}")
      assert response(conn, 404)
    end
  end

  describe "invoke function" do
    setup [:create_function]

    test "invokes function without passing args", %{
      conn: conn,
      function: %Function{name: function_name},
      module_name: module_name
    } do
      Core.Cluster.Mock |> Mox.expect(:all_nodes, fn -> [:worker@localhost] end)

      Core.Commands.Mock
      |> Mox.expect(:send_invoke, fn _, _, _, _, _, _ -> {:ok, %{result: "Hello, World!"}} end)

      conn = post(conn, ~p"/v1/fn/#{module_name}/#{function_name}")
      assert response(conn, 200)
    end

    test "invokes function with args", %{
      conn: conn,
      function: %Function{name: function_name},
      module_name: module_name
    } do
      Core.Cluster.Mock |> Mox.expect(:all_nodes, fn -> [:worker@localhost] end)

      Core.Commands.Mock
      |> Mox.expect(:send_invoke, fn _, _, _, _, _, _ -> {:ok, %{result: "Hello, World!"}} end)

      conn = post(conn, ~p"/v1/fn/#{module_name}/#{function_name}", args: %{name: "World"})

      assert response(conn, 200)
    end

    test "invokes function when worker does not have function", %{
      conn: conn,
      function: %Function{name: function_name},
      module_name: module_name
    } do
      Core.Cluster.Mock |> Mox.expect(:all_nodes, fn -> [:worker@localhost] end)

      Core.Commands.Mock
      |> Mox.expect(:send_invoke, fn _, _, _, _, _, _ -> {:error, :code_not_found, self()} end)

      conn = post(conn, ~p"/v1/fn/#{module_name}/#{function_name}")
      assert response(conn, 200)
    end

    test "renders errors when no worker is available", %{
      conn: conn,
      function: %Function{name: function_name},
      module_name: module_name
    } do
      Core.Cluster.Mock |> Mox.expect(:all_nodes, fn -> [] end)

      conn = post(conn, ~p"/v1/fn/#{module_name}/#{function_name}")
      assert response(conn, 503)
    end

    test "renders error when function does not exist", %{conn: conn} do
      Core.Cluster.Mock |> Mox.expect(:all_nodes, 0, fn -> [:worker@localhost] end)
      conn = post(conn, ~p"/v1/fn/som_module/no_function")
      assert response(conn, 404)
    end

    test "renders error when module does not exist", %{conn: conn} do
      Core.Cluster.Mock |> Mox.expect(:all_nodes, 0, fn -> [:worker@localhost] end)
      conn = post(conn, ~p"/v1/fn/no_module/some_function")
      assert response(conn, 404)
    end

    test "renders error when there is an exec error", %{
      conn: conn,
      function: %Function{name: function_name},
      module_name: module_name
    } do
      Core.Cluster.Mock |> Mox.expect(:all_nodes, fn -> [:worker@localhost] end)

      Core.Commands.Mock
      |> Mox.expect(:send_invoke, fn _, _, _, _, _, _ ->
        {:error, {:exec_error, "some reason"}}
      end)

      conn = post(conn, ~p"/v1/fn/#{module_name}/#{function_name}")
      assert response(conn, 422)
    end
  end

  defp create_function(_) do
    module = module_fixture()
    function = function_fixture(module.id)
    _metadata = function_metadata_fixture(function.id)
    %{function: function, module_name: module.name}
  end
end

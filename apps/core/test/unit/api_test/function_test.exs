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

defmodule ApiTest.FunctionTest do
  alias Core.Domain.Api
  alias Core.Domain.FunctionStruct

  use ExUnit.Case, async: true
  import Mox, only: [verify_on_exit!: 1]
  use Plug.Test

  setup :verify_on_exit!

  describe "API functions" do
    setup do
      Core.FunctionStore.Mock
      |> Mox.stub_with(Core.Adapters.FunctionStore.Test)

      :ok
    end

    test "new should return {:ok, function_name} when no error occurs" do
      f = %{
        "name" => "hello",
        "module" => "ns",
        "code" => "console.log(\"hello\")"
      }

      assert Api.FunctionRepo.new(f) == {:ok, "hello"}
    end

    test "new should return {:error, :bad_params} when the given parameter map lacks the necessary keys" do
      f = %{"name" => "hello"}
      assert Api.FunctionRepo.new(f) == {:error, :bad_params}
    end

    test "new should return {:ok, function_name} and ignore unused parameters when unnecessary keys are given" do
      f = %{
        "name" => "hello",
        "code" => "some code",
        "something_else" => "something else",
        "module" => "ns"
      }

      Core.FunctionStore.Mock
      |> Mox.expect(:insert_function, 1, fn %FunctionStruct{
                                              name: "hello",
                                              code: "some code",
                                              module: "ns"
                                            } ->
        {:ok, "hello"}
      end)
      |> Mox.expect(:insert_function, 0, fn _ -> {:error, "some error"} end)

      assert Api.FunctionRepo.new(f) == {:ok, "hello"}
    end

    test "new should return {:error, {:bad_insert, reason}} when the underlying storage fails" do
      f = %{
        "name" => "hello",
        "module" => "ns",
        "code" => "console.log(\"hello\")"
      }

      Core.FunctionStore.Mock
      |> Mox.expect(:insert_function, 1, fn _ -> {:error, {:aborted, "some error"}} end)

      assert Api.FunctionRepo.new(f) == {:error, {:bad_insert, "some error"}}
    end

    test "delete should return {:ok, function_name} when no error occurs" do
      assert Api.FunctionRepo.delete(%{"name" => "hello", "module" => "ns"}) ==
               {:ok, "hello"}
    end

    test "delete should return {:error, :bad_params} when the given parameter map lacks the necessary keys" do
      assert Api.FunctionRepo.delete(%{"module" => "ns"}) == {:error, :bad_params}
    end

    test "delete should return {:error, {:bad_delete, reason}} when the underlying store returns an error" do
      Core.FunctionStore.Mock
      |> Mox.expect(:delete_function, 1, fn "hello", "ns" ->
        {:error, {:aborted, "for some reason"}}
      end)

      assert Api.FunctionRepo.delete(%{"name" => "hello", "module" => "ns"}) ==
               {:error, {:bad_delete, "for some reason"}}
    end

    test "delete should return {:error, :not_found} when the function is not found" do
      Core.FunctionStore.Mock |> Mox.expect(:exists?, 1, fn _, _ -> false end)

      assert Api.FunctionRepo.delete(%{"name" => "not here", "module" => "ns"}) ==
               {:error, {:bad_delete, :not_found}}
    end

    test "list should return {:ok, functions} when no error occurs" do
      assert Api.FunctionRepo.list(%{"module" => "ns"}) ==
               {:ok, []}

      Core.FunctionStore.Mock
      |> Mox.expect(:list_functions, 1, fn "ns" -> {:ok, ["f1", "f2"]} end)

      assert Api.FunctionRepo.list(%{"module" => "ns"}) ==
               {:ok, ["f1", "f2"]}
    end

    test "list should return {:error, {:bad_list, reason}} when the underlying store returns an error" do
      Core.FunctionStore.Mock
      |> Mox.expect(:list_functions, 1, fn "ns" ->
        {:error, {:aborted, "for some reason"}}
      end)

      assert Api.FunctionRepo.list(%{"module" => "ns"}) ==
               {:error, {:bad_list, "for some reason"}}
    end

    test "list should return {:error, :bad_params} when the module is missing" do
      assert Api.FunctionRepo.list(%{}) ==
               {:error, :bad_params}
    end
  end
end

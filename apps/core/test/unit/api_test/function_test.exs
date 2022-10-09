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

    test "new_function should return {:ok, %{result: function_name}} when no error occurs" do
      f = %{
        "name" => "hello",
        "namespace" => "ns",
        "code" => "console.log(\"hello\")"
      }

      assert Api.FunctionRepo.new(f) == {:ok, "hello"}
    end

    test "new_function should return {:error, :bad_params} when the given parameter map lacks the necessary keys" do
      f = %{"name" => "hello"}
      assert Api.FunctionRepo.new(f) == {:error, :bad_params}
    end

    test "new_function should return {:ok, function_name} and ignore unused parameters in the input map when unnecessary keys are given" do
      f = %{
        "name" => "hello",
        "code" => "some code",
        "image" => "nodejs",
        "something_else" => "something else",
        "namespace" => "ns"
      }

      Core.FunctionStore.Mock
      |> Mox.expect(:insert_function, 1, fn %FunctionStruct{
                                              name: "hello",
                                              code: "some code",
                                              image: "nodejs",
                                              namespace: "ns"
                                            } ->
        {:ok, "hello"}
      end)
      |> Mox.expect(:insert_function, 0, fn _ -> {:error, "some error"} end)

      assert Api.FunctionRepo.new(f) == {:ok, "hello"}
    end

    test "delete_function should return {:ok, %{result => function_name}} when no error occurs" do
      assert Api.FunctionRepo.delete(%{"name" => "hello", "namespace" => "ns"}) ==
               {:ok, "hello"}
    end

    test "delete_function should return {:error, :bad_params}  when the given parameter map lacks the necessary keys" do
      assert Api.FunctionRepo.delete(%{"namespace" => "ns"}) == {:error, :bad_params}
    end
  end
end

# Licensed to the Apache Software Foundation (ASF) under one
# or more contributor license agreements.  See the NOTICE file
# distributed with this work for additional information
# regarding copyright ownership.  The ASF licenses this file
# to you under the Apache License, Version 2.0 (the
# "License"); you may not use this file except in compliance
# with the License.  You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing,
# software distributed under the License is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
# KIND, either express or implied.  See the License for the
# specific language governing permissions and limitations
# under the License.
#
defmodule WorkerTest do
  use ExUnit.Case, async: true
  alias Core.Adapters.Commands.Worker
  alias Core.Domain.FunctionStruct

  test "should send to {:worker, worker atom}" do
    assert Worker.worker_address(:worker@atom) == {:worker, :worker@atom}
  end

  test "should prepare correct invocation command" do
    function = %FunctionStruct{name: "test", image: "nodejs", code: "some code", namespace: "_"}

    assert Worker.invoke_command(function, %{}) ==
             {:invoke, function, %{}}
  end
end

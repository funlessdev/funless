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
defmodule ApiTest do
  alias Core.Domain.Api
  alias Core.Domain.Internal.Invoker

  use ExUnit.Case, async: true

  describe "Scheduler" do
    test "select should return a worker" do
      expected = :worker
      w_nodes = [:worker]
      workers = Scheduler.select(w_nodes)

      assert workers == expected
    end

    test "select should return :no_workers when empty list" do
      expected = :no_workers
      w_nodes = []
      workers = Scheduler.select(w_nodes)

      assert workers == expected
    end
  end
end

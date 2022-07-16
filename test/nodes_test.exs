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

defmodule NodesTest do
  use ExUnit.Case, async: true
  alias Core.Domain.Nodes
  import Mox, only: [verify_on_exit!: 1]

  setup :verify_on_exit!

  describe "Cluster" do
    test "should return the list of nodes" do
      # credo:disable-for-next-line
      assert Node.list() == Core.Adapters.Cluster.all_nodes()
    end
  end

  describe "Nodes" do
    setup do
      Core.Cluster.Mock |> Mox.stub_with(Core.Adapters.Cluster.Test)
      :ok
    end

    test "worker_nodes should return empty list when no node is connected" do
      nodes = []
      Core.Cluster.Mock |> Mox.expect(:all_nodes, fn -> nodes end)
      workers = Nodes.worker_nodes()
      assert workers == []
    end

    test "worker_nodes should return empty list when there are only non-worker nodes" do
      nodes = [:"core@example.com", :"extra@127.1.0.2"]
      Core.Cluster.Mock |> Mox.expect(:all_nodes, fn -> nodes end)
      workers = Nodes.worker_nodes()
      assert workers == []
    end

    test "worker_nodes should return a filtered list of only worker nodes when present" do
      expected = [:"worker@127.0.0.1", :"worker@ciao.it"]
      nodes = [:"worker@127.0.0.1", :"core@example.com", :"worker@ciao.it", :"extra@127.1.0.2"]
      Core.Cluster.Mock |> Mox.stub(:all_nodes, fn -> nodes end)
      workers = Nodes.worker_nodes()
      assert workers == expected
    end
  end
end

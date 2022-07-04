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

defmodule FunlessWorkerTest do
  use ExUnit.Case
  doctest FunlessWorker

  test "greets the world" do
    assert FunlessWorker.hello() == :world
  end
end

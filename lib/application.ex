defmodule WorkerApp do
  use Application

  def start(_type, _args) do
    children = [{Worker.Worker, []}]
    Supervisor.start_link(children, strategy: :one_for_one)
  end
end

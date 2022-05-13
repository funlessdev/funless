defmodule WorkerApp do
  use Application

  def start(_type, _args) do
    children = [{Worker.Updater, []}, {Worker.Worker, []}]
    Supervisor.start_link(children, strategy: :rest_for_one)
  end
end

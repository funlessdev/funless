defmodule Worker.Server do
  @moduledoc """

  """
  use GenServer, restart: :permanent

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: :worker)
  end

  @impl true
  def init(_args) do
    # Process.flag(:trap_exit, true)
    IO.puts("worker running")
    {:ok, nil}
  end

  @impl true
  def handle_call({:prepare, function}, from, _state) do
    spawn(Worker.Worker, :prepare_container, [function, from])
    {:noreply, nil}
  end

  @impl true
  def handle_call({:run, function}, from, _state) do
    spawn(Worker.Worker, :run_function, [function, from])
    {:noreply, nil}
  end

  @impl true
  def handle_call({:invoke, function}, from, _state) do
    spawn(Worker.Worker, :invoke_function, [function, from])
    {:noreply, nil}
  end

  @impl true
  def handle_call({:cleanup, function}, from, _state) do
    spawn(Worker.Worker, :cleanup, [function, from])
    {:noreply, nil}
  end

end

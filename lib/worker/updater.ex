defmodule Worker.Updater do
  use GenServer, restart: :permanent

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: :updater)
  end

  @impl true
  def init(_args) do
    # TODO: table needs to be repopulated after a crash => how do we check underlying docker for function->container associations?
    table = :ets.new(:functions_containers, [:named_table, :protected])
    IO.puts("updater running")
    {:ok, table}
  end

  @impl true
  def handle_call({:insert, function_name, container_name}, _from, table) do
    :ets.insert(table, {function_name, container_name})
    {:reply, {:ok, container_name}, table}
  end

  @impl true
  def handle_call({:delete, function_name, container_name}, _from, table) do
    :ets.delete_object(table, {function_name, container_name})
    {:reply, :ok, table}
  end

end

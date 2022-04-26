defmodule Worker.Worker do
  alias Worker.Fn

  def prepare_container(container_name, image_name, tar_path, main_file) do
    Fn.prepare_container(container_name, image_name, tar_path, main_file)
    receive do
      :ok ->
        :ok
      {:error, err} ->
        IO.puts("Error while preparing container:\n#{err}")
        :error
    end
  end

  def run_function(container_name) do
    Fn.run_function(container_name)
    receive do
      {:ok, logs} ->
        IO.puts("Logs from container:\n#{logs}")
      {:error, err} ->
        IO.puts("Error while running function: #{err}")
        :error
    end

  end

  def cleanup(container_name) do
    Fn.cleanup(container_name)
    receive do
      :ok ->
        :ok
      {:error, err} ->
        IO.puts("Error while cleaning up container: #{err}")
        :error
    end
  end

  def pipeline(_args) do
    prepare_container("funless-node-container", "node:lts-alpine", "js/hello.tar.gz", "/opt/index.js")
    run_function("funless-node-container")
    cleanup("funless-node-container")
  end

  def worker(fn_to_containers) do
    #TODO: get result from spawned subprocesses and forward it to sender
    #TODO: handle container replicas
    #TODO: handle automatic removal of containers (scale-to-zero) for inactive functions
    Process.flag(:trap_exit, true)
    IO.inspect(fn_to_containers)
    receive do
      {:prepare, function_name, image_name, tar_path, main_file, _sender} ->
        container_name = function_name <> "-funless-container"
        _subproc_pid = spawn_link(__MODULE__, :prepare_container, [container_name, image_name, tar_path, main_file])
        worker(Map.put(fn_to_containers, function_name, container_name))

      {:run, function_name, _sender} ->
        IO.puts("run")
        container_name = fn_to_containers[function_name]
        _subproc_pid = spawn_link(__MODULE__, :run_function, [container_name])
        worker(fn_to_containers)

      {:cleanup, function_name, _sender} ->
        IO.puts("cleanup")
        container_name = fn_to_containers[function_name]
        _subproc_pid = spawn_link(__MODULE__, :cleanup, [container_name])
        worker(Map.delete(fn_to_containers, function_name))

      {:EXIT, pid, reason} ->
        #TODO: handle when a prepare_container function exits and remove the related {function,container} tuple from map
        IO.puts("Received an EXIT message")
        IO.inspect({:EXIT, pid, reason})
        worker(fn_to_containers)

      other_messages ->
        IO.inspect(other_messages)
        worker(fn_to_containers)

    end
  end



  def child_spec(args) do
    %{
      id: Worker,
      start: {__MODULE__, :init, [args]},
      restart: :permanent,
      type: :worker
    }
  end

  def init(_args) do
    IO.puts("started")
    pid = spawn_link(__MODULE__, :worker, [%{}])
    Process.register(pid, :worker)
    {:ok, pid}
  end

end

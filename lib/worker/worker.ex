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
        IO.puts("Logs from container:\n#{logs}\n")
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
    receive do
      {:prepare, _function, _image_name, _tar_path, _main_file, _sender} ->
        IO.puts("prepare")
        worker(fn_to_containers)

      {:run, _function, _sender} ->
        IO.puts("run")
        worker(fn_to_containers)

      {:cleanup, _function} ->
        IO.puts("cleanup")
        worker(fn_to_containers)

      _ ->
        IO.puts("other")
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
    pid = spawn_link(__MODULE__, :worker, [[]])
    Process.register(pid, :worker)
    {:ok, pid}
  end

end

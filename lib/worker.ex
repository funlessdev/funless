defmodule Worker do
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

  def pipeline do
    prepare_container("funless-node-container", "node:lts-alpine", "js/hello.tar.gz", "/opt/index.js")
    run_function("funless-node-container")
    cleanup("funless-node-container")
  end
end

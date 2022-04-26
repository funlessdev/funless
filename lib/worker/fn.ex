defmodule Worker.Fn do
  use Rustler, otp_app: :worker, crate: :fn

  def prepare_container(_container_name, _image_name, _tar_path, _main_file) do
    :erlang.nif_error(:nif_not_loaded)
  end

  def run_function(_container_name) do
    :erlang.nif_error(:nif_not_loaded)
  end

  def cleanup(_container_name) do
    :erlang.nif_error(:nif_not_loaded)
  end
end

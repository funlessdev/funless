defmodule Fn do
  use Rustler, otp_app: :worker, crate: :fn

  def prepare_container() do
    :erlang.nif_error(:nif_not_loaded)
  end

  def run_function() do
    :erlang.nif_error(:nif_not_loaded)
  end

  def cleanup() do
    :erlang.nif_error(:nif_not_loaded)
  end
end

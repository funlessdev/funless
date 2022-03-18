defmodule Scheduler do
  use Rustler, otp_app: :core, crate: :scheduler

  def add(_a, _b) do
    :erlang.nif_error(:nif_not_loaded)
  end

  def subtract(_a, _b) do
    :erlang.nif_error(:nif_not_loaded)
  end
end

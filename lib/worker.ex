defmodule Worker do
  def hello do
    Fn.prepare_container()
    IO.puts(Fn.run_function())
    Fn.cleanup()
  end
end

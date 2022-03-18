defmodule Core do
  @moduledoc """
  Documentation for `Core`.
  """

  @doc """
  Hello world.

  ## Examples

      iex> Core.hello()
      :world

  """
  def hello do
    IO.puts(Scheduler.add(2, 3))
    IO.puts(Scheduler.subtract(6, 8))
  end
end

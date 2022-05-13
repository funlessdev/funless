defmodule Worker.Function do
  @enforce_keys [:name, :image, :archive]
  defstruct [:name, :image, :archive, :main_file]
end

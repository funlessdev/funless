defmodule CoreWeb.ModuleJSON do
  alias Core.Schemas.Module
  alias CoreWeb.FunctionJSON

  @doc """
  Renders a list of modules.
  """
  def index(%{modules: modules}) do
    %{data: for(module <- modules, do: data(module))}
  end

  @doc """
  Renders a single module.
  """
  def show(%{module: module}) do
    %{data: data(module)}
  end

  def show_functions(%{module_name: name, functions: functions}) do
    funs =
      for(function <- functions, do: FunctionJSON.show(%{function: function}))
      |> Enum.map(fn f -> f.data end)

    %{data: %{name: name, functions: funs}}
  end

  defp data(%Module{} = module) do
    %{
      name: module.name
    }
  end
end

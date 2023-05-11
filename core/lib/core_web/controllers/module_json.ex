defmodule CoreWeb.ModuleJSON do
  alias Core.Schemas.Module
  alias CoreWeb.FunctionJson

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
    %{data: %{name: name, functions: for(function <- functions, do: FunctionJson.show(function))}}
  end

  defp data(%Module{} = module) do
    %{
      name: module.name
    }
  end
end

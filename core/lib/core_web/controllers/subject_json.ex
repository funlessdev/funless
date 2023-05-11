defmodule CoreWeb.SubjectJSON do
  alias Core.Schemas.Subject

  @doc """
  Renders a list of subjects.
  """
  def index(%{subjects: subjects}) do
    %{data: for(subject <- subjects, do: data(subject))}
  end

  @doc """
  Renders a single subject.
  """
  def show(%{subject: subject}) do
    %{data: data(subject)}
  end

  defp data(%Subject{} = subject) do
    %{
      name: subject.name,
      token: subject.token
    }
  end
end

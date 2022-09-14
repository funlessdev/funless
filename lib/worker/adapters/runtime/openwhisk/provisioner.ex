defmodule Worker.Adapters.Runtime.OpenWhisk.Provisioner do
  alias Worker.Domain.RuntimeStruct

  @behaviour Worker.Domain.Ports.Runtime.Provisioner

  @impl true
  def prepare(_, _) do
    {:ok, %RuntimeStruct{name: "hello-runtime", host: "localhost", port: "8080"}}
  end

  @impl true
  def init(_, _) do
    :ok
  end

  @doc """
    Checks the DOCKER_HOST environment variable for the docker socket path.
    If an incorrect path is found, the default is used instead.

    Returns the complete socket path, protocol included.
  """
  def docker_socket do
    default = "unix:///var/run/docker.sock"
    docker_env = System.get_env("DOCKER_HOST", default)

    case Regex.run(~r/^((unix|tcp|http):\/\/)(.*)$/, docker_env) do
      nil -> default
      [socket | _] -> socket
    end
  end
end

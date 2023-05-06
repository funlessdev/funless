# Copyright 2023 Giuseppe De Palma, Matteo Trentin
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

defmodule Worker.Adapters.Runtime.Provisioner.Test do
  @moduledoc false
  @behaviour Worker.Domain.Ports.Runtime.Provisioner
  alias Data.ExecutionResource

  @impl true
  def provision(_) do
    {:ok, %ExecutionResource{resource: "runtime"}}
  end
end

defmodule Worker.Adapters.Runtime.Runner.Test do
  @moduledoc false
  @behaviour Worker.Domain.Ports.Runtime.Runner

  @impl true
  def run_function(_worker_function, _args, _runtime) do
    {:ok, %{"result" => "test-output"}}
  end
end

defmodule Worker.Adapters.Runtime.Cleaner.Test do
  @moduledoc false
  @behaviour Worker.Domain.Ports.Runtime.Cleaner

  @impl true
  def cleanup(_runtime) do
    :ok
  end
end

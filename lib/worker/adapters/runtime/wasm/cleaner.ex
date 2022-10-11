# Copyright 2022 Giuseppe De Palma, Matteo Trentin
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

defmodule Worker.Adapters.Runtime.Wasm.Cleaner do
  @moduledoc """
    Adapter for WebAssembly runtime removal.
    Since we are running no permanent container, the removal is not necessary; as such, no operation is performed,
    and the runtime is simply returned to the caller.
  """
  @behaviour Worker.Domain.Ports.Runtime.Cleaner

  @impl true
  def cleanup(_runtime), do: :ok
end

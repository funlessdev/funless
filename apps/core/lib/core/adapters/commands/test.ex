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

defmodule Core.Adapters.Commands.Test do
  @moduledoc false
  @behaviour Core.Domain.Ports.Commands

  alias Core.Domain.InvokeResult

  @impl true
  def send_invoke(_worker, name, _ns, _args) do
    {:ok, %InvokeResult{result: name}}
  end

  @impl true
  def send_invoke_with_code(_worker, function, _args) do
    {:ok, %InvokeResult{result: function.name}}
  end
end

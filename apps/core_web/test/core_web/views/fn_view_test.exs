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

defmodule CoreWeb.FnViewTest do
  use CoreWeb.ConnCase, async: true

  # Bring render/3 and render_to_string/3 for testing custom views
  import Phoenix.View

  test "create.json" do
    result = render(CoreWeb.FnView, "create.json", %{function_name: "test"})
    assert result == %{result: "test"}
  end

  test "delete.json" do
    result = render(CoreWeb.FnView, "delete.json", %{function_name: "test"})
    assert result == %{result: "test"}
  end
end

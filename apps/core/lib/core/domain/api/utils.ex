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

defmodule Core.Domain.Api.Utils do
  @moduledoc false

  @doc """
  Checks the given namespace string and returns the validated version of it.

  ## Parameters
  - ns: the namespace string to validate

  ## Returns
  - "_": if the string is nil, empty or blank (all whitespace), the default "_"
  - String.trim(ns): otherwise, the trimmed version of the string is returned
  """
  @spec validate_namespace(String.t()) :: String.t()
  def validate_namespace(ns) do
    namespace = ns |> to_string |> String.trim()

    if namespace == "" do
      "_"
    else
      namespace
    end
  end
end

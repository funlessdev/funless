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

defmodule Worker.Adapters.Runtime.Wasm.Nif do
  @moduledoc """
  NIFs used to interact with WebAssembly runtimes.
  """
  use Rustler, otp_app: :worker, crate: :fn_wasm, mode: :release

  # Engine NIFs
  @doc false
  def init, do: error()

  @doc false
  def compile_module(_engine, _code), do: error()

  @doc false
  def run_function(_engine, _module, _args), do: error()

  defp error, do: :erlang.nif_error(:nif_not_loaded)
end
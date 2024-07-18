# Copyright 2024 Giuseppe De Palma, Matteo Trentin
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

defmodule Data.Configurations.CAPP.Block do
  @moduledoc """
  Struct encoding a Block in a cAPP configuration script.
  Generally used as content for %CAPP.Tag{}.

  ## Fields
  - workers: either a list of String or the single "*" String.
             Encodes the desired workers when using this block in scheduling
             ("*" meaning all available workers).
  - strategy: standard APP strategy, with additional :"min-latency" allowed strategy.
              This selects the worker with the lowest (calculated) latency among the ones available.
  - invalidate: standard APP invalidate, with additional :max_latency key.
                Indicates the maximum (calculated) latency allowed for the selected node.
  """
  @type t :: %__MODULE__{
          strategy: :random | :"best-first" | :platform | :min_latency,
          workers: String.t() | [String.t()],
          invalidate: %{
            capacity_used: number() | :infinity,
            max_concurrent_invocations: number() | :infinity,
            max_latency: number() | :infinity
          }
        }
  defstruct [
    :workers,
    strategy: :"best-first",
    invalidate: %{
      capacity_used: :infinity,
      max_concurrent_invocations: :infinity,
      max_latency: :infinity
    }
  ]
end

defmodule Data.Configurations.CAPP.Tag do
  @moduledoc """
  Struct encoding a Tag in a cAPP configuration script.
  Generally used as content for %CAPP{}.

  ## Fields
  - blocks: a list of APP.Block structs, each encoding a single block defined for the tag in the APP script.
  - followup: either the :default or the :fail atom, extracted from the APP script.
  """
  @type t :: %__MODULE__{
          blocks: [Data.Configurations.CAPP.Block.t()],
          followup: :default | :fail
        }
  defstruct [:blocks, followup: :fail]
end

defmodule Data.Configurations.CAPP do
  @moduledoc """
  Struct encoding a cAPP configuration script.
  Generally produced by Core.Domain.Policies.Parsers.CAPP.parse/1.

  ## Fields
  - tags: map with String keys and cAPP.Tag values.
          Associates the name of each tag with the struct encoding the tag.
  """
  @type t :: %__MODULE__{
          tags: %{
            String.t() => Data.Configurations.CAPP.Tag
          }
        }
  defstruct [:tags]
end

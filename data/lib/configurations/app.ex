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

defmodule Data.Configurations.APP.Block do
  @moduledoc """
  Struct encoding a Block in an APP configuration script.
  Generally used as content for %APP.Tag{}.

  ## Fields
  - workers: either a list of String or the single "*" String.
             Encodes the desired workers when using this block in scheduling
             ("*" meaning all available workers).
  - strategy: either the :random, :"best-first" or :platform atom.
              Encodes the strategy that will be used to select worker, when using this block in scheduling.
  - invalidate: a map with :capacity_used and :max_concurrent_invocations keys, with values extracted from an APP script.
                Encodes conditions used to determine whether a given worker is valid,
                when using this block in scheduling.
  - affinity: a map with :affinity and :antiaffinity keys. Currently unused.
  """
  @type t :: %__MODULE__{
          strategy: :random | :"best-first" | :platform,
          workers: String.t() | [String.t()],
          invalidate: %{
            capacity_used: number() | :infinity,
            max_concurrent_invocations: number() | :infinity
          },
          affinity: %{
            affnity: [String.t()],
            antiaffinity: [String.t()]
          }
        }
  defstruct [
    :workers,
    affinity: %{
      affinity: [],
      antiaffinity: []
    },
    strategy: :"best-first",
    invalidate: %{capacity_used: :infinity, max_concurrent_invocations: :infinity}
  ]
end

defmodule Data.Configurations.APP.Tag do
  @moduledoc """
  Struct encoding a Tag in an APP configuration script.
  Generally used as content for %APP{}.

  ## Fields
  - blocks: a list of APP.Block structs, each encoding a single block defined for the tag in the APP script.
  - followup: either the :default or the :fail atom, extracted from the APP script.
  """
  @type t :: %__MODULE__{
          blocks: [Data.Configurations.APP.Block.t()],
          followup: :default | :fail
        }
  defstruct [:blocks, followup: :fail]
end

defmodule Data.Configurations.APP do
  @moduledoc """
  Struct encoding an APP configuration script.
  Generally produced by Core.Domain.Policies.Parsers.APP.parse/1.

  ## Fields
  - tags: map with String keys and APP.Tag values.
          Associates the name of each tag with the struct encoding the tag.
  """
  @type t :: %__MODULE__{
          tags: %{
            String.t() => Data.Configurations.APP.Tag
          }
        }
  defstruct [:tags]
end

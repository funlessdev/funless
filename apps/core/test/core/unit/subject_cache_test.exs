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

defmodule Integration.SubjectCacheTest do
  use ExUnit.Case

  alias Core.Adapters.Subjects.Cache

  import Mox, only: [verify_on_exit!: 1]

  setup :verify_on_exit!

  test "SubjectCache get returns a :subject_not_found when no subject" do
    result = Cache.get("non-existent-subject")
    assert result == :subject_not_found
  end

  test "insert adds subject => token into the cache" do
    token = "some-token"
    assert Cache.get("test") == :subject_not_found
    assert :ok = Cache.insert("test", token)
    assert Cache.get("test") == token
    assert :ok = Cache.delete("test")
  end

  test "delete on empty empty does nothing" do
    assert Cache.get("test") == :subject_not_found
    assert :ok = Cache.delete("test")
  end
end

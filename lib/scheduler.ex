# Licensed to the Apache Software Foundation (ASF) under one
# or more contributor license agreements.  See the NOTICE file
# distributed with this work for additional information
# regarding copyright ownership.  The ASF licenses this file
# to you under the Apache License, Version 2.0 (the
# "License"); you may not use this file except in compliance
# with the License.  You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing,
# software distributed under the License is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
# KIND, either express or implied.  See the License for the
# specific language governing permissions and limitations
# under the License.
#
defmodule Scheduler do
  @moduledoc "Interface of the rust scheduler module."

  use Rustler, otp_app: :core, crate: :scheduler

  @doc """
  Receives a list of workers (FnWorker struct) and chooses one which can be used for invocation.
  """
  def select(_arg1) do
    :erlang.nif_error(:nif_not_loaded)
  end
end

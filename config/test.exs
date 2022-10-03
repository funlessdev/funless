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

import Config

config :worker, Worker.Domain.Ports.RuntimeTracker, adapter: Worker.RuntimeTracker.Mock
config :worker, Worker.Domain.Ports.Runtime.Provisioner, adapter: Worker.Provisioner.Mock
config :worker, Worker.Domain.Ports.Runtime.Runner, adapter: Worker.Runner.Mock
config :worker, Worker.Domain.Ports.Runtime.Cleaner, adapter: Worker.Cleaner.Mock

# Logs turned off without backends (use :console to see them)
config :logger, level: :warn, backends: []

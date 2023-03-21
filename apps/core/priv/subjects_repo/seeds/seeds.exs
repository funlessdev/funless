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

# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     Core.Repo.insert!(%Core.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

alias Core.SubjectsRepo
alias Core.Schemas.Subject
alias Core.Schemas.Admin

signed_token = CoreWeb.Token.sign(%{user: "guest"})
SubjectsRepo.insert!(%Subject{name: "guest", token: signed_token})

admin_token = CoreWeb.Token.sign(%{user: "admin"})
SubjectsRepo.insert!(%Admin{name: "admin", token: admin_token})


file_path = :core |> Application.compile_env!(Core.Seeds) |> Keyword.fetch!(:path)

with :ok <- File.mkdir_p(Path.dirname(file_path)) do
  File.write(file_path, "Admin=#{admin_token}\nGuest=#{signed_token}")
end

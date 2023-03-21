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

defmodule Core.SubjectsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Core.Domain.Subjects` and `Core.Domain.Admins` contexts.
  """
  alias Core.Domain.Admins
  alias Core.Domain.Subjects

  @doc """
  Generate a subject.
  """
  def subject_fixture(attrs \\ %{}) do
    {:ok, subject} =
      attrs
      |> Enum.into(%{
        name: "some_name",
        token: "some_token"
      })
      |> Subjects.create_subject()

    subject
  end

  @doc """
  Generate a admin.
  """
  def admin_fixture(attrs \\ %{}) do
    {:ok, admin} =
      attrs
      |> Enum.into(%{
        name: "some_name",
        token: "some_token"
      })
      |> Admins.create_admin()

    admin
  end
end

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

defmodule Core.SubjectsTest do
  use Core.SubjectsDataCase

  alias Core.Domain.Subjects

  describe "subjects" do
    alias Core.Schemas.Subject

    import Core.SubjectsFixtures

    @invalid_attrs %{name: nil, token: nil}

    test "list_subjects/0 returns all subjects" do
      subject = subject_fixture()
      assert Subjects.list_subjects() == [subject]
    end

    test "get_subject!/1 returns the subject with given id" do
      subject = subject_fixture()
      assert Subjects.get_subject!(subject.id) == subject
    end

    test "create_subject/1 with valid data creates a subject" do
      valid_attrs = %{name: "some_name", token: "some_token"}

      assert {:ok, %Subject{} = subject} = Subjects.create_subject(valid_attrs)
      assert subject.name == "some_name"
      assert subject.token == "some_token"
    end

    test "create_subject/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Subjects.create_subject(@invalid_attrs)
    end

    # test "update_subject/2 with valid data updates the subject" do
    #   subject = subject_fixture()
    #   update_attrs = %{name: "some_updated_name", token: "some_updated_token"}

    #   assert {:ok, %Subject{} = subject} = Subjects.update_subject(subject, update_attrs)
    #   assert subject.name == "some_updated_name"
    #   assert subject.token == "some_updated_token"
    # end

    # test "update_subject/2 with invalid data returns error changeset" do
    #   subject = subject_fixture()
    #   assert {:error, %Ecto.Changeset{}} = Subjects.update_subject(subject, @invalid_attrs)
    #   assert subject == Subjects.get_subject!(subject.id)
    # end

    # test "delete_subject/1 deletes the subject" do
    #   subject = subject_fixture()
    #   assert {:ok, %Subject{}} = Subjects.delete_subject(subject)
    #   assert_raise Ecto.NoResultsError, fn -> Subjects.get_subject!(subject.id) end
    # end

    test "change_subject/1 returns a subject changeset" do
      subject = subject_fixture()
      assert %Ecto.Changeset{} = Subjects.change_subject(subject)
    end
  end
end

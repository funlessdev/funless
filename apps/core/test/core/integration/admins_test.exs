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

defmodule Core.AdminsTest do
  use Core.DataCase

  alias Core.Domain.Admins

  describe "admins" do
    alias Core.Schemas.Admin

    import Core.SubjectsFixtures

    @invalid_attrs %{name: nil, token: nil}

    test "list_admins/0 returns all admins" do
      admin = admin_fixture()
      assert Admins.list_admins() == [admin]
    end

    test "get_admin!/1 returns the admin with given id" do
      admin = admin_fixture()
      assert Admins.get_admin!(admin.id) == admin
    end

    test "create_admin/1 with valid data creates a admin" do
      valid_attrs = %{name: "some name", token: "some token"}

      assert {:ok, %Admin{} = admin} = Admins.create_admin(valid_attrs)
      assert admin.name == "some name"
      assert admin.token == "some token"
    end

    test "create_admin/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Admins.create_admin(@invalid_attrs)
    end

    test "update_admin/2 with valid data updates the admin" do
      admin = admin_fixture()
      update_attrs = %{name: "some updated name", token: "some updated token"}

      assert {:ok, %Admin{} = admin} = Admins.update_admin(admin, update_attrs)
      assert admin.name == "some updated name"
      assert admin.token == "some updated token"
    end

    test "update_admin/2 with invalid data returns error changeset" do
      admin = admin_fixture()
      assert {:error, %Ecto.Changeset{}} = Admins.update_admin(admin, @invalid_attrs)
      assert admin == Admins.get_admin!(admin.id)
    end

    test "delete_admin/1 deletes the admin" do
      admin = admin_fixture()
      assert {:ok, %Admin{}} = Admins.delete_admin(admin)
      assert_raise Ecto.NoResultsError, fn -> Admins.get_admin!(admin.id) end
    end

    test "change_admin/1 returns a admin changeset" do
      admin = admin_fixture()
      assert %Ecto.Changeset{} = Admins.change_admin(admin)
    end
  end
end

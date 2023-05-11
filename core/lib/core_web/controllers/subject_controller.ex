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

defmodule CoreWeb.SubjectController do
  use CoreWeb, :controller

  require Logger

  alias Core.Domain.Subjects
  alias Core.Schemas.Subject

  action_fallback(CoreWeb.FallbackController)

  def index(conn, _params) do
    subjects = Subjects.list_subjects()
    render(conn, :index, subjects: subjects)
  end

  def create(conn, %{"subject" => %{"name" => name}}) do
    signed_token = CoreWeb.Token.sign(%{user: name})

    with {:ok, %Subject{} = subject} <-
           Subjects.create_subject(%{name: name, token: signed_token}) do
      conn
      |> put_status(:created)
      |> render(:show, subject: subject)
    end
  end

  def show(conn, %{"id" => id}) do
    subject = Subjects.get_subject!(id)
    render(conn, :show, subject: subject)
  end

  # def update(conn, %{"id" => id, "subject" => subject_params}) do
  #   subject = Subjects.get_subject!(id)

  #   with {:ok, %Subject{} = subject} <- Subjects.update_subject(subject, subject_params) do
  #     render(conn, :show, subject: subject)
  #   end
  # end

  # def delete(conn, %{"id" => id}) do
  #   subject = Subjects.get_subject!(id)

  #   with {:ok, %Subject{}} <- Subjects.delete_subject(subject) do
  #     send_resp(conn, :no_content, "")
  #   end
  # end
end

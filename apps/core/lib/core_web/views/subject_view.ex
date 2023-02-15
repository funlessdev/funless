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

defmodule CoreWeb.SubjectView do
  use CoreWeb, :view
  alias CoreWeb.SubjectView

  def render("index.json", %{subjects: subjects}) do
    %{data: render_many(subjects, SubjectView, "subject.json")}
  end

  def render("show.json", %{subject: subject}) do
    %{data: render_one(subject, SubjectView, "subject.json")}
  end

  def render("subject.json", %{subject: subject}) do
    %{
      id: subject.id,
      name: subject.name,
      token: subject.token
    }
  end
end

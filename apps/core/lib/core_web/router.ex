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

defmodule CoreWeb.Router do
  use CoreWeb, :router

  pipeline :api do
    plug(:accepts, ["json"])
  end

  scope "/v1", CoreWeb do
    pipe_through(:api)

    # A simple get "/" to health check
    get("/", DefaultController, :index)

    # Admin routes (Subjects)
    resources("/admin/subjects", SubjectController, except: [:new, :edit])

    # --- Public API routes ---

    # List all modules
    get("/fn", ModuleController, :index)
    # Create new module
    post("/fn", ModuleController, :create)

    # List all functions in a module
    get("/fn/:module_name", ModuleController, :show_functions)
    # Create new function in a module
    post("/fn/:module_name", FunctionController, :create)
    # Update module name
    put("/fn/:module_name", ModuleController, :update)
    # Delete module
    delete("/fn/:module_name", ModuleController, :delete)

    # Show single function information
    get("/fn/:module_name/:function_name", FunctionController, :show)
    # Update single function
    put("/fn/:module_name/:function_name", FunctionController, :update)
    # Delete single function
    delete("/fn/:module_name/:function_name", FunctionController, :delete)

    # Invoke function
    post("/fn/:module_name/:function_name", FunctionController, :invoke)
  end

  # Enables LiveDashboard only for development
  #
  # If you want to use the LiveDashboard in production, you should put
  # it behind authentication and allow only admins to access it.
  # If your application does not have an admins-only section yet,
  # you can use Plug.BasicAuth to set up some basic authentication
  # as long as you are also using SSL (which you should anyway).
  if Mix.env() in [:dev, :test] do
    import Phoenix.LiveDashboard.Router

    scope "/" do
      pipe_through([:fetch_session, :protect_from_forgery])

      live_dashboard("/dashboard",
        metrics: CoreWeb.Telemetry,
        ecto_repos: [Core.Repo, Core.SubjectsRepo]
      )
    end
  end
end

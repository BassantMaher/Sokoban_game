defmodule AuthServiceWeb.Router do
  use AuthServiceWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", AuthServiceWeb do
    pipe_through :api

    get "/", PageController, :home
  end

  scope "/api", AuthServiceWeb do
    pipe_through :api

    post "/register", RegistrationController, :create
    post "/login", SessionController, :create
    delete "/logout", SessionController, :delete
    post "/verify", UserController, :verify_token
    get "/user/:id", UserController, :show
  end
end

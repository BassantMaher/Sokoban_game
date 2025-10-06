defmodule GameServiceWeb.Router do
  use GameServiceWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {GameServiceWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", GameServiceWeb do
    pipe_through :browser

    get "/", PageController, :home
    live "/game", GameLive, :index
  end

  # LiveView routes for development
  import Phoenix.LiveView.Router

  scope "/", GameServiceWeb do
    pipe_through :browser

    live_session :default do
      live "/play", GameLive, :index
    end
  end

  # Other scopes may use custom stacks.
  # scope "/api", GameServiceWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:game_service, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: GameServiceWeb.Telemetry
    end
  end
end

defmodule SokobanTask1Web.Router do
  use SokobanTask1Web, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {SokobanTask1Web.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug Guardian.Plug.Pipeline, module: SokobanTask1.Guardian,
                                  error_handler: SokobanTask1Web.AuthErrorHandler
    plug Guardian.Plug.VerifySession, claims: %{"typ" => "access"}
    plug Guardian.Plug.LoadResource, allow_blank: true
    plug SokobanTask1Web.AuthPlugs, :load_current_user
  end

  pipeline :api do
    plug :accepts, ["json"]
    plug Corsica, origins: "*", allow_headers: :all, allow_methods: :all
  end

  pipeline :api_auth do
    plug SokobanTask1Web.AuthPlugs, :authenticate_api
  end

  pipeline :api_maybe_auth do
    plug SokobanTask1Web.AuthPlugs, :maybe_authenticate_api
  end

  pipeline :require_auth do
    plug SokobanTask1Web.AuthPlugs, :require_auth
  end

  pipeline :require_no_auth do
    plug SokobanTask1Web.AuthPlugs, :require_no_auth
  end

  pipeline :require_admin do
    plug SokobanTask1Web.AuthPlugs, :require_admin
  end

  # Public routes
  scope "/", SokobanTask1Web do
    pipe_through :browser

    live "/", GameLive
    get "/login", AuthController, :login
    get "/register", AuthController, :register
  end

  # Authentication routes
  scope "/auth", SokobanTask1Web do
    pipe_through [:browser, :require_no_auth]

    post "/login", AuthController, :create_session
    post "/register", AuthController, :create_user
  end

  # Protected routes
  scope "/", SokobanTask1Web do
    pipe_through [:browser, :require_auth]

    live "/game", GameLive
    post "/auth/logout", AuthController, :logout
  end

  # Admin routes
  scope "/admin", SokobanTask1Web do
    pipe_through [:browser, :require_admin]

    get "/dashboard", AdminController, :dashboard
    get "/users", AdminController, :users
    get "/levels", AdminController, :levels
    post "/levels", AdminController, :create_level
    put "/levels/:id", AdminController, :update_level
    delete "/levels/:id", AdminController, :delete_level
  end

  # API routes - Authentication
  scope "/api/auth", SokobanTask1Web.API do
    pipe_through :api

    post "/login", AuthController, :login
    post "/register", AuthController, :register
    post "/refresh", AuthController, :refresh_token
    post "/logout", AuthController, :logout
  end

  # API routes - Authenticated
  scope "/api", SokobanTask1Web.API do
    pipe_through [:api, :api_auth]

    get "/profile", AuthController, :profile

    # Game endpoints
    get "/levels", GameController, :levels
    get "/levels/:id", GameController, :level
    post "/sessions/start", GameController, :start_session
    get "/sessions/active/:level_id", GameController, :active_session
    put "/sessions/:session_id/move", GameController, :make_move
    put "/sessions/:session_id/complete", GameController, :complete_session
    put "/sessions/:session_id/abandon", GameController, :abandon_session

    # Scores and leaderboards
    get "/levels/:level_id/leaderboard", GameController, :leaderboard
    get "/user/scores", GameController, :user_scores
    get "/user/progress", GameController, :user_progress
  end

  # API routes - Public (with optional auth)
  scope "/api/public", SokobanTask1Web.API do
    pipe_through [:api, :api_maybe_auth]

    get "/levels", GameController, :levels
    get "/levels/:level_id/leaderboard", GameController, :leaderboard
  end

  # Enable LiveDashboard in development
  if Application.compile_env(:sokoban_task1, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: SokobanTask1Web.Telemetry
    end
  end
end

defmodule AuthServiceWeb.PageController do
  use AuthServiceWeb, :controller

  def home(conn, _params) do
    # Return a simple JSON response indicating this is the auth service
    json(conn, %{
      service: "AuthService",
      message: "Welcome to the Sokoban Game Authentication Service",
      endpoints: [
        "POST /api/register - Register a new user",
        "POST /api/login - Login user",
        "DELETE /api/logout - Logout user",
        "POST /api/verify - Verify JWT token",
        "GET /api/user/:id - Get user details"
      ],
      game_service: "http://localhost:4000"
    })
  end
end

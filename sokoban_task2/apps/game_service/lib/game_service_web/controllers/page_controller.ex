defmodule GameServiceWeb.PageController do
  use GameServiceWeb, :controller

  def home(conn, _params) do
    # Redirect to the live game
    redirect(conn, to: "/game")
  end
end

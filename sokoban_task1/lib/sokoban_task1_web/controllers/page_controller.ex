defmodule SokobanTask1Web.PageController do
  use SokobanTask1Web, :controller

  def redirect_to_login(conn, _params) do
    redirect(conn, to: "/login")
  end
end

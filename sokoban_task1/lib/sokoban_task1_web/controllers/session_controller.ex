defmodule SokobanTask1Web.SessionController do
  use SokobanTask1Web, :controller

  alias SokobanTask1Web.Auth

  def delete(conn, _params) do
    conn
    |> Auth.log_out_user()
    |> put_flash(:info, "Logged out successfully.")
    |> redirect(to: "/login")
  end
end

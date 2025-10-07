defmodule SokobanTask1Web.AuthController do
  use SokobanTask1Web, :controller

  alias SokobanTask1Web.Auth
  alias SokobanTask1.Accounts

  def login_user(conn, %{"id" => id}) do
    user = Accounts.get_user!(String.to_integer(id))

    conn
    |> Auth.log_in_user(user)
    |> redirect(to: "/game")
  end

  def login_anonymous(conn, _params) do
    conn
    |> Auth.log_in_anonymous()
    |> redirect(to: "/game")
  end
end

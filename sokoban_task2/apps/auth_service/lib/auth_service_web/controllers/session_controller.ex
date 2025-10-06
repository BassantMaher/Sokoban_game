defmodule AuthServiceWeb.SessionController do
  use AuthServiceWeb, :controller

  alias AuthService.Accounts
  alias AuthService.Guardian

  def create(conn, %{"email" => email, "password" => password}) do
    case Accounts.authenticate_user(email, password) do
      {:ok, user} ->
        case Guardian.encode_and_sign(user) do
          {:ok, token, _claims} ->
            conn
            |> put_status(:ok)
            |> json(%{
              success: true,
              token: token,
              user: %{
                id: user.id,
                email: user.email,
                name: user.name,
                role: user.role.name
              }
            })

          {:error, _reason} ->
            conn
            |> put_status(:internal_server_error)
            |> json(%{success: false, message: "Failed to generate token"})
        end

      {:error, _reason} ->
        conn
        |> put_status(:unauthorized)
        |> json(%{success: false, message: "Invalid email or password"})
    end
  end

  def delete(conn, _params) do
    case Guardian.Plug.current_token(conn) do
      nil ->
        conn
        |> put_status(:ok)
        |> json(%{success: true, message: "Logged out"})

      token ->
        case Guardian.revoke(token) do
          {:ok, _claims} ->
            conn
            |> put_status(:ok)
            |> json(%{success: true, message: "Logged out"})

          {:error, _reason} ->
            conn
            |> put_status(:internal_server_error)
            |> json(%{success: false, message: "Failed to logout"})
        end
    end
  end
end

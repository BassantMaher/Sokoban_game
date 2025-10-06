defmodule AuthServiceWeb.UserController do
  use AuthServiceWeb, :controller

  alias AuthService.Accounts
  alias AuthService.Guardian

  plug Guardian.Plug.Pipeline, module: AuthService.Guardian, error_handler: AuthServiceWeb.ErrorHandler
  plug Guardian.Plug.VerifyHeader
  plug Guardian.Plug.LoadResource

  def show(conn, %{"id" => id}) do
    case Accounts.get_user(id) do
      nil ->
        conn
        |> put_status(:not_found)
        |> json(%{success: false, message: "User not found"})

      user ->
        conn
        |> put_status(:ok)
        |> json(%{
          success: true,
          user: %{
            id: user.id,
            email: user.email,
            name: user.name,
            role: user.role.name
          }
        })
    end
  end

  def verify_token(conn, %{"token" => token}) do
    case Guardian.decode_and_verify(token) do
      {:ok, claims} ->
        case Guardian.resource_from_claims(claims) do
          {:ok, user} ->
            # Verify token exists in Redis
            key = "token:#{user.id}"
            case Redix.command(:redix, ["GET", key]) do
              {:ok, ^token} ->
                conn
                |> put_status(:ok)
                |> json(%{
                  success: true,
                  user: %{
                    id: user.id,
                    email: user.email,
                    name: user.name,
                    role: user.role.name
                  }
                })

              {:ok, nil} ->
                conn
                |> put_status(:unauthorized)
                |> json(%{success: false, message: "Token not found or expired"})

              {:error, _} ->
                conn
                |> put_status(:internal_server_error)
                |> json(%{success: false, message: "Redis error"})
            end

          {:error, _} ->
            conn
            |> put_status(:unauthorized)
            |> json(%{success: false, message: "Invalid token"})
        end

      {:error, _} ->
        conn
        |> put_status(:unauthorized)
        |> json(%{success: false, message: "Invalid token"})
    end
  end
end

defmodule SokobanTask1Web.API.AuthController do
  use SokobanTask1Web, :controller

  alias SokobanTask1.{Accounts, Guardian}

  @doc """
  API login endpoint.
  """
  def login(conn, %{"email_or_username" => email_or_username, "password" => password}) do
    case Accounts.authenticate_user(email_or_username, password) do
      {:ok, user} ->
        case Guardian.create_tokens(user) do
          {:ok, tokens} ->
            conn
            |> put_status(:ok)
            |> json(%{
              success: true,
              message: "Login successful",
              user: %{
                id: user.id,
                username: user.username,
                email: user.email,
                display_name: user.display_name
              },
              tokens: tokens
            })

          {:error, _reason} ->
            conn
            |> put_status(:internal_server_error)
            |> json(%{success: false, message: "Token generation failed"})
        end

      {:error, :invalid_credentials} ->
        conn
        |> put_status(:unauthorized)
        |> json(%{success: false, message: "Invalid email/username or password"})
    end
  end

  @doc """
  API registration endpoint.
  """
  def register(conn, %{"user" => user_params}) do
    case Accounts.create_user(user_params) do
      {:ok, user} ->
        case Guardian.create_tokens(user) do
          {:ok, tokens} ->
            conn
            |> put_status(:created)
            |> json(%{
              success: true,
              message: "Account created successfully",
              user: %{
                id: user.id,
                username: user.username,
                email: user.email,
                display_name: user.display_name
              },
              tokens: tokens
            })

          {:error, _reason} ->
            conn
            |> put_status(:internal_server_error)
            |> json(%{success: false, message: "Token generation failed"})
        end

      {:error, changeset} ->
        errors =
          changeset.errors
          |> Enum.map(fn {field, {message, _}} ->
            %{field: field, message: message}
          end)

        conn
        |> put_status(:unprocessable_entity)
        |> json(%{
          success: false,
          message: "Validation failed",
          errors: errors
        })
    end
  end

  @doc """
  API token refresh endpoint.
  """
  def refresh_token(conn, %{"refresh_token" => refresh_token}) do
    case Guardian.refresh_token(refresh_token) do
      {:ok, new_access_token, _claims} ->
        conn
        |> put_status(:ok)
        |> json(%{
          success: true,
          access_token: new_access_token
        })

      {:error, _reason} ->
        conn
        |> put_status(:unauthorized)
        |> json(%{success: false, message: "Invalid refresh token"})
    end
  end

  @doc """
  API logout endpoint (invalidate tokens).
  """
  def logout(conn, _params) do
    # In a production app, you might want to maintain a token blacklist
    # For now, we'll just return success since JWT tokens are stateless
    conn
    |> put_status(:ok)
    |> json(%{success: true, message: "Logged out successfully"})
  end

  @doc """
  Get current user profile.
  """
  def profile(conn, _params) do
    user = conn.assigns.current_user

    conn
    |> put_status(:ok)
    |> json(%{
      success: true,
      user: %{
        id: user.id,
        username: user.username,
        email: user.email,
        display_name: user.display_name,
        games_played: user.games_played,
        levels_completed: user.levels_completed,
        total_score: user.total_score,
        inserted_at: user.inserted_at,
        updated_at: user.updated_at
      }
    })
  end
end

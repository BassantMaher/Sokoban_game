defmodule AuthServiceWeb.RegistrationController do
  use AuthServiceWeb, :controller

  alias AuthService.Accounts
  alias AuthService.Guardian

  def create(conn, %{"user" => user_params}) do
    # Default to player role if not specified
    player_role = Accounts.get_role_by_name("player")
    user_params = Map.put(user_params, "role_id", player_role.id)

    case Accounts.create_user(user_params) do
      {:ok, user} ->
        case Guardian.encode_and_sign(user) do
          {:ok, token, _claims} ->
            conn
            |> put_status(:created)
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

      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{
          success: false,
          message: "Registration failed",
          errors: format_errors(changeset)
        })
    end
  end

  defp format_errors(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Regex.replace(~r"%{(\w+)}", msg, fn _, key ->
        opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
      end)
    end)
  end
end

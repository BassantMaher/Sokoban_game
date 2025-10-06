defmodule SokobanTask1Web.AuthController do
  use SokobanTask1Web, :controller

  alias SokobanTask1.{Accounts, Guardian}
  alias SokobanTask1.Accounts.User

  @doc """
  Show login form.
  """
  def login(conn, _params) do
    changeset = User.login_changeset(%User{}, %{})
    render(conn, :login, changeset: changeset)
  end

  @doc """
  Handle login form submission.
  """
  def create_session(conn, %{"user" => user_params}) do
    %{"email_or_username" => email_or_username, "password" => password} = user_params

    case Accounts.authenticate_user(email_or_username, password) do
      {:ok, user} ->
        {:ok, _token, _claims} = Guardian.encode_and_sign(user)

        conn
        |> Guardian.Plug.sign_in(user)
        |> put_flash(:info, "Welcome back, #{user.username}!")
        |> redirect(to: ~p"/game")

      {:error, :invalid_credentials} ->
        changeset =
          %User{}
          |> User.login_changeset(user_params)
          |> Ecto.Changeset.add_error(:email_or_username, "Invalid email/username or password")

        conn
        |> put_flash(:error, "Invalid email/username or password")
        |> render(:login, changeset: changeset)
    end
  end

  @doc """
  Show registration form.
  """
  def register(conn, _params) do
    changeset = User.registration_changeset(%User{}, %{})
    render(conn, :register, changeset: changeset)
  end

  @doc """
  Handle registration form submission.
  """
  def create_user(conn, %{"user" => user_params}) do
    case Accounts.create_user(user_params) do
      {:ok, user} ->
        conn
        |> Guardian.Plug.sign_in(user)
        |> put_flash(:info, "Account created successfully! Welcome, #{user.username}!")
        |> redirect(to: ~p"/game")

      {:error, changeset} ->
        conn
        |> put_flash(:error, "Please fix the errors below")
        |> render(:register, changeset: changeset)
    end
  end

  @doc """
  Handle logout.
  """
  def logout(conn, _params) do
    conn
    |> Guardian.Plug.sign_out()
    |> put_flash(:info, "Logged out successfully")
    |> redirect(to: ~p"/")
  end
end

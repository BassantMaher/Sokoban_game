defmodule SokobanTask1Web.Auth do
  @moduledoc """
  Authentication plug for managing user sessions.
  """

  import Plug.Conn
  import Phoenix.Controller

  alias SokobanTask1.Accounts

  @doc """
  Fetches the current user from session and assigns to connection.
  """
  def fetch_current_user(conn, _opts) do
    user_id = get_session(conn, :user_id)
    is_anonymous = get_session(conn, :anonymous)

    cond do
      is_anonymous ->
        assign(conn, :current_user, nil)
        |> assign(:anonymous, true)

      user_id ->
        user = Accounts.get_user!(user_id)
        assign(conn, :current_user, user)
        |> assign(:anonymous, false)

      true ->
        assign(conn, :current_user, nil)
        |> assign(:anonymous, false)
    end
  rescue
    Ecto.NoResultsError ->
      assign(conn, :current_user, nil)
      |> assign(:anonymous, false)
  end

  @doc """
  Requires authentication - redirects to login if not authenticated or anonymous.
  """
  def require_authenticated_or_anonymous(conn, _opts) do
    if conn.assigns[:current_user] || conn.assigns[:anonymous] do
      conn
    else
      conn
      |> put_flash(:error, "You must log in or play as anonymous to access this page.")
      |> redirect(to: "/login")
      |> halt()
    end
  end

  @doc """
  Requires admin role - redirects if not admin.
  """
  def require_admin(conn, _opts) do
    user = conn.assigns[:current_user]

    if user && user.role == "admin" do
      conn
    else
      conn
      |> put_flash(:error, "You must be an admin to access this page.")
      |> redirect(to: "/game")
      |> halt()
    end
  end

  @doc """
  Redirects if user is already logged in.
  """
  def redirect_if_authenticated(conn, _opts) do
    if conn.assigns[:current_user] || conn.assigns[:anonymous] do
      conn
      |> redirect(to: "/game")
      |> halt()
    else
      conn
    end
  end

  @doc """
  Logs in a user.
  """
  def log_in_user(conn, user) do
    conn
    |> put_session(:user_id, user.id)
    |> delete_session(:anonymous)
    |> configure_session(renew: true)
  end

  @doc """
  Logs in as anonymous.
  """
  def log_in_anonymous(conn) do
    conn
    |> delete_session(:user_id)
    |> put_session(:anonymous, true)
    |> configure_session(renew: true)
  end

  @doc """
  Logs out a user.
  """
  def log_out_user(conn) do
    conn
    |> configure_session(drop: true)
  end
end

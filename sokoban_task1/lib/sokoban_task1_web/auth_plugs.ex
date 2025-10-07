defmodule SokobanTask1Web.AuthPlugs do
  @moduledoc """
  Authentication plugs for handling user sessions and API authentication.
  """

  import Plug.Conn
  import Phoenix.Controller

  alias SokobanTask1.Guardian

  def init(opts), do: opts

  def call(conn, opts) do
    case opts do
      :load_current_user -> load_current_user(conn, opts)
      :require_auth -> require_auth(conn, opts)
      :require_no_auth -> require_no_auth(conn, opts)
      :require_admin -> require_admin(conn, opts)
      :authenticate_api -> authenticate_api(conn, opts)
      :maybe_authenticate_api -> maybe_authenticate_api(conn, opts)
      _ -> conn
    end
  end

  @doc """
  Loads the current user from the session if available.
  """
  def load_current_user(conn, _opts) do
    current_user = Guardian.Plug.current_resource(conn)
    assign(conn, :current_user, current_user)
  end

  @doc """
  Requires the user to be authenticated. Redirects to login if not.
  """
  def require_auth(conn, _opts) do
    if conn.assigns[:current_user] do
      conn
    else
      conn
      |> put_flash(:error, "You must be logged in to access this page")
      |> redirect(to: "/login")
      |> halt()
    end
  end

  @doc """
  Requires the user to NOT be authenticated. Redirects to game if logged in.
  """
  def require_no_auth(conn, _opts) do
    if conn.assigns[:current_user] do
      conn
      |> put_flash(:info, "You are already logged in")
      |> redirect(to: "/game")
      |> halt()
    else
      conn
    end
  end

  @doc """
  Requires the user to be an admin. Redirects to unauthorized if not admin.
  """
  def require_admin(conn, _opts) do
    case conn.assigns[:current_user] do
      %{is_admin: true} ->
        conn
      %{is_admin: false} ->
        conn
        |> put_flash(:error, "You must be an admin to access this page")
        |> redirect(to: "/")
        |> halt()
      nil ->
        conn
        |> put_flash(:error, "You must be logged in as an admin to access this page")
        |> redirect(to: "/login")
        |> halt()
    end
  end

  @doc """
  Authenticates API requests using Bearer token.
  """
  def authenticate_api(conn, _opts) do
    case get_req_header(conn, "authorization") do
      ["Bearer " <> token] ->
        case Guardian.decode_and_verify(token) do
          {:ok, claims} ->
            case Guardian.resource_from_claims(claims) do
              {:ok, user} ->
                assign(conn, :current_user, user)
              {:error, _reason} ->
                send_unauthorized(conn)
            end
          {:error, _reason} ->
            send_unauthorized(conn)
        end
      _ ->
        send_unauthorized(conn)
    end
  end

  @doc """
  Optionally authenticates API requests. Continues even if no token provided.
  """
  def maybe_authenticate_api(conn, _opts) do
    case get_req_header(conn, "authorization") do
      ["Bearer " <> token] ->
        case Guardian.decode_and_verify(token) do
          {:ok, claims} ->
            case Guardian.resource_from_claims(claims) do
              {:ok, user} ->
                assign(conn, :current_user, user)
              {:error, _reason} ->
                assign(conn, :current_user, nil)
            end
          {:error, _reason} ->
            assign(conn, :current_user, nil)
        end
      _ ->
        assign(conn, :current_user, nil)
    end
  end

  # Private helper functions

  defp send_unauthorized(conn) do
    conn
    |> put_status(:unauthorized)
    |> json(%{error: "Unauthorized"})
    |> halt()
  end
end

defmodule SokobanTask1Web.AuthErrorHandler do
  @moduledoc """
  Error handler for Guardian authentication failures.
  """

  import Phoenix.Controller

  @behaviour Guardian.Plug.ErrorHandler

  @impl Guardian.Plug.ErrorHandler
  def auth_error(conn, {type, _reason}, _opts) do
    body = to_string(type)

    conn
    |> put_flash(:error, "Authentication error: #{body}")
    |> redirect(to: "/login")
  end
end

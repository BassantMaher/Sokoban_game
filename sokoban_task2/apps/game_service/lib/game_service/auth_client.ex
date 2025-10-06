defmodule GameService.AuthClient do
  @moduledoc """
  HTTP client for communicating with Auth Service
  """

  use Tesla

  plug Tesla.Middleware.BaseUrl, "http://localhost:4001/api"
  plug Tesla.Middleware.JSON

  @doc "Verify user token with Auth Service"
  def verify_token(token) do
    case post("/verify", %{token: token}) do
      {:ok, %Tesla.Env{status: 200, body: %{"success" => true, "user" => user}}} ->
        {:ok, user}

      {:ok, %Tesla.Env{status: 401}} ->
        {:error, :unauthorized}

      {:ok, %Tesla.Env{status: status}} ->
        {:error, {:http_error, status}}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc "Get user by ID"
  def get_user(id) do
    case get("/user/#{id}") do
      {:ok, %Tesla.Env{status: 200, body: %{"success" => true, "user" => user}}} ->
        {:ok, user}

      {:ok, %Tesla.Env{status: 404}} ->
        {:error, :not_found}

      {:ok, %Tesla.Env{status: status}} ->
        {:error, {:http_error, status}}

      {:error, reason} ->
        {:error, reason}
    end
  end
end

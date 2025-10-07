defmodule SokobanTask1.Guardian do
  @moduledoc """
  Guardian configuration for JWT token management.
  """
  use Guardian, otp_app: :sokoban_task1

  alias SokobanTask1.Accounts

  def subject_for_token(%{id: id}, _claims) do
    {:ok, to_string(id)}
  end

  def subject_for_token(_, _) do
    {:error, :reason_for_error}
  end

  def resource_from_claims(%{"sub" => id}) do
    case Accounts.get_user(id) do
      nil -> {:error, :resource_not_found}
      user -> {:ok, user}
    end
  end

  def resource_from_claims(_claims) do
    {:error, :reason_for_error}
  end

  @doc """
  Generates a token for a user.
  """
  def generate_token(user) do
    encode_and_sign(user)
  end

  @doc """
  Gets user from token.
  """
  def get_user_from_token(token) do
    case decode_and_verify(token) do
      {:ok, claims} -> resource_from_claims(claims)
      error -> error
    end
  end

  @doc """
  Verifies and extracts user from token.
  """
  def verify_token(token) do
    decode_and_verify(token)
  end

  @doc """
  Creates tokens for authentication (access + refresh).
  """
  def create_tokens(user) do
    with {:ok, access_token, _claims} <- encode_and_sign(user, %{}, token_type: "access"),
         {:ok, refresh_token, _claims} <- encode_and_sign(user, %{}, token_type: "refresh") do
      {:ok, %{access_token: access_token, refresh_token: refresh_token}}
    end
  end

  @doc """
  Refreshes an access token using a refresh token.
  """
  def refresh_token(refresh_token) do
    with {:ok, _claims} <- decode_and_verify(refresh_token, %{"typ" => "refresh"}),
         {:ok, user, _claims} <- resource_from_token(refresh_token) do
      encode_and_sign(user, %{}, token_type: "access")
    end
  end
end

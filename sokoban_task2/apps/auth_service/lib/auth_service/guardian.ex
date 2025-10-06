defmodule AuthService.Guardian do
  use Guardian, otp_app: :auth_service

  alias AuthService.Accounts

  def subject_for_token(%{id: id}, _claims) do
    {:ok, to_string(id)}
  end

  def subject_for_token(_, _) do
    {:error, :invalid_resource}
  end

  def resource_from_claims(%{"sub" => id}) do
    case Accounts.get_user(id) do
      nil -> {:error, :invalid_user}
      user -> {:ok, user}
    end
  end

  def resource_from_claims(_claims) do
    {:error, :invalid_claims}
  end

  def after_encode_and_sign(resource, _claims, token, _options) do
    with {:ok, _} <- store_token_in_redis(resource.id, token) do
      {:ok, token}
    end
  end

  def on_revoke(claims, token, _options) do
    with {:ok, resource} <- resource_from_claims(claims) do
      remove_token_from_redis(resource.id, token)
    end
  end

  defp store_token_in_redis(user_id, token) do
    key = "token:#{user_id}"
    expiry = System.get_env("TOKEN_EXPIRY_SECONDS") || "2592000" |> String.to_integer()
    Redix.command(:redix, ["SET", key, token, "EX", expiry])
  end

  defp remove_token_from_redis(user_id, _token) do
    key = "token:#{user_id}"
    Redix.command(:redix, ["DEL", key])
  end
end

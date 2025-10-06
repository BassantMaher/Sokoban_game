defmodule SokobanTask1.Env do
  @moduledoc """
  Environment configuration helper for Sokoban game.
  Loads environment variables from .env files and provides type-safe access.
  """

  @doc """
  Load environment variables from .env file based on current environment.
  """
  def load_env do
    env_file = case Mix.env() do
      :prod -> ".env.prod"
      :test -> ".env.test"
      _ -> ".env"
    end

    if File.exists?(env_file) do
      env_file
      |> File.read!()
      |> String.split("\n")
      |> Enum.each(&load_line/1)
    end
  end

  defp load_line(line) do
    line = String.trim(line)

    # Skip comments and empty lines
    unless String.starts_with?(line, "#") or line == "" do
      case String.split(line, "=", parts: 2) do
        [key, value] ->
          # Remove quotes if present
          value = String.trim(value, "\"")
          System.put_env(key, value)
        _ ->
          :ok
      end
    end
  end

  @doc """
  Get environment variable with fallback.
  """
  def get(key, default \\ nil) do
    System.get_env(key) || default
  end

  @doc """
  Get environment variable as integer.
  """
  def get_integer(key, default \\ nil) do
    case get(key) do
      nil -> default
      value -> String.to_integer(value)
    end
  end

  @doc """
  Get environment variable as boolean.
  """
  def get_boolean(key, default \\ false) do
    case get(key) do
      nil -> default
      value -> value in ["true", "1", "yes", "on"]
    end
  end

  @doc """
  Get database configuration from environment.
  """
  def database_config do
    [
      url: get("DATABASE_URL"),
      hostname: get("DATABASE_HOST", "localhost"),
      username: get("DATABASE_USER", "postgres"),
      password: get("DATABASE_PASSWORD", "postgres"),
      database: get("DATABASE_NAME", "sokoban_dev"),
      pool_size: get_integer("DATABASE_POOL_SIZE", 10)
    ]
  end

  @doc """
  Get Redis configuration from environment.
  """
  def redis_config do
    base_config = case get("REDIS_URL") do
      nil ->
        [host: "localhost", port: 6379]
      url ->
        parse_redis_url(url)
    end

    # Add name to the configuration
    [name: :redix] ++ base_config
  end

  defp parse_redis_url(url) do
    uri = URI.parse(url)

    config = [
      host: uri.host || "localhost",
      port: uri.port || 6379
    ]

    config = if uri.userinfo do
      [password: String.split(uri.userinfo, ":") |> List.last()] ++ config
    else
      config
    end

    config = if uri.scheme == "rediss" do
      [ssl: true, ssl_opts: [verify: :verify_none]] ++ config
    else
      config
    end

    if uri.path && uri.path != "/" do
      db = String.trim_leading(uri.path, "/") |> String.to_integer()
      [database: db] ++ config
    else
      config
    end
  end

  @doc """
  Get JWT secret from environment.
  """
  def jwt_secret do
    get("JWT_SECRET_KEY") ||
    "your-super-secret-jwt-key-at-least-64-characters-long-for-security-purposes"
  end

  @doc """
  Get Phoenix secret key base from environment.
  """
  def secret_key_base do
    get("SECRET_KEY_BASE") ||
    "your-phoenix-secret-key-base-generate-with-mix-phx-gen-secret-minimum-64-chars"
  end

  @doc """
  Get session timeout in seconds.
  """
  def session_timeout do
    get_integer("TOKEN_EXPIRY_SECONDS", 30 * 24 * 60 * 60) # 30 days
  end
end

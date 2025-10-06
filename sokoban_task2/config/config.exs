# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

# Load environment variables from .env files
env_file = case Mix.env() do
  :prod -> ".env.prod"
  :test -> ".env.test"
  _ -> ".env"
end

if File.exists?(env_file) do
  env_file
  |> File.read!()
  |> String.split("\n")
  |> Enum.each(fn line ->
    line = String.trim(line)
    unless String.starts_with?(line, "#") or line == "" do
      case String.split(line, "=", parts: 2) do
        [key, value] ->
          value = String.trim(value, "\"")
          System.put_env(key, value)
        _ -> :ok
      end
    end
  end)
end

# Helper function to get environment variable with fallback
get_env = fn key, default -> System.get_env(key) || default end
get_env_int = fn key, default ->
  case System.get_env(key) do
    nil -> default
    value -> String.to_integer(value)
  end
end

# Configure the shared database
config :sokoban_task2, SokobanTask2.Repo,
  url: get_env.("DATABASE_URL", nil),
  hostname: get_env.("DATABASE_HOST", "localhost"),
  username: get_env.("DATABASE_USER", "postgres"),
  password: get_env.("DATABASE_PASSWORD", "postgres"),
  database: get_env.("DATABASE_NAME", "sokoban_task2_dev"),
  pool_size: get_env_int.("DATABASE_POOL_SIZE", 10)

# Configure Ecto repos for each app
config :sokoban_task2, ecto_repos: [SokobanTask2.Repo]
config :auth_service, ecto_repos: [SokobanTask2.Repo]
config :game_service, ecto_repos: [SokobanTask2.Repo]

# Configure Redix for JWT token storage
redis_url = get_env.("REDIS_URL", "redis://localhost:6379")
redis_config = if String.contains?(redis_url, "://") do
  uri = URI.parse(redis_url)
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
    [ssl: true, socket_opts: [verify: :verify_none]] ++ config
  else
    config
  end

  if uri.path && uri.path != "/" do
    db = String.trim_leading(uri.path, "/") |> String.to_integer()
    [database: db] ++ config
  else
    config
  end
else
  [host: "localhost", port: 6379]
end

config :sokoban_task2, :redis, redis_config

# Auth Service configuration
config :auth_service, AuthServiceWeb.Endpoint,
  http: [
    ip: {0, 0, 0, 0},
    port: get_env_int.("AUTH_SERVICE_PORT", 4001)
  ],
  check_origin: String.split(get_env.("CORS_ORIGINS", "http://localhost:4000,http://localhost:4001"), ","),
  code_reloader: true,
  debug_errors: true,
  secret_key_base: get_env.("SECRET_KEY_BASE", "crAbJlBJ2kN9Sd9BSXnkGgkmi0hdSCVB+H7a3mOk4WN1ADuJlkB2AG/3biBqKbbxbJBKDLASNZsmdkjk45nqwkjnefij"),
  pubsub_server: AuthService.PubSub,
  watchers: []

# Game Service configuration
config :game_service, GameServiceWeb.Endpoint,
  http: [
    ip: {0, 0, 0, 0},
    port: get_env_int.("GAME_SERVICE_PORT", 4000)
  ],
  check_origin: String.split(get_env.("CORS_ORIGINS", "http://localhost:4000,http://localhost:4001"), ","),
  code_reloader: true,
  debug_errors: true,
  secret_key_base: get_env.("SECRET_KEY_BASE", "crAbJlBJ2kN9Sd9BSXnkGgkmi0hdSCVB+H7a3mOk4WN1ADuJlkB2AG/3biBqKbbxbJBKDLASNZsmdkjk45nqwkjnefij"),
  pubsub_server: GameService.PubSub,
  live_view: [signing_salt: "GGwDyXgrWwCevwkK"],
  watchers: []

# Guardian configuration for JWT
config :auth_service, AuthService.Guardian,
  issuer: "auth_service",
  secret_key: get_env.("JWT_SECRET_KEY", "YourJWTSecretKeyMinimum64Characters1234567890123456789012345678"),
  ttl: {get_env_int.("TOKEN_EXPIRY_SECONDS", 2_592_000), :seconds}

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Disable Tesla deprecated builder warning
config :tesla, disable_deprecated_builder_warning: true

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"

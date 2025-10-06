# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

# Load environment variables
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

config :sokoban_task1,
  ecto_repos: [SokobanTask1.Repo],
  generators: [timestamp_type: :utc_datetime]

# Database configuration
config :sokoban_task1, SokobanTask1.Repo,
  url: get_env.("DATABASE_URL", "postgresql://postgres:postgres@localhost:5432/sokoban_dev"),
  hostname: get_env.("DATABASE_HOST", "localhost"),
  username: get_env.("DATABASE_USER", "postgres"),
  password: get_env.("DATABASE_PASSWORD", "postgres"),
  database: get_env.("DATABASE_NAME", "sokoban_dev"),
  stacktrace: true,
  show_sensitive_data_on_connection_error: true,
  pool_size: get_env_int.("DATABASE_POOL_SIZE", 10)

# Configures the endpoint
config :sokoban_task1, SokobanTask1Web.Endpoint,
  url: [host: get_env.("PHX_HOST", "localhost")],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    formats: [html: SokobanTask1Web.ErrorHTML, json: SokobanTask1Web.ErrorJSON],
    layout: false
  ],
  pubsub_server: SokobanTask1.PubSub,
  live_view: [signing_salt: "sokoban_salt"],
  secret_key_base: get_env.("SECRET_KEY_BASE", "your-phoenix-secret-key-base-generate-with-mix-phx-gen-secret-minimum-64-chars-12345")

# Guardian configuration for JWT
config :sokoban_task1, SokobanTask1.Guardian,
  issuer: "sokoban_task1",
  secret_key: get_env.("JWT_SECRET_KEY", "your-super-secret-jwt-key-at-least-64-characters-long-for-security-purposes-12345"),
  ttl: {get_env_int.("TOKEN_EXPIRY_SECONDS", 2_592_000), :seconds}

# Configure esbuild (the version is required)
config :esbuild,
  version: "0.17.11",
  sokoban_task1: [
    args:
      ~w(js/app.js --bundle --target=es2017 --outdir=../priv/static/assets --external:/fonts/* --external:/images/*),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ]

# Configure tailwind (the version is required)
config :tailwind,
  version: "3.3.0",
  sokoban_task1: [
    args: ~w(
      --config=tailwind.config.js
      --input=css/app.css
      --output=../priv/static/assets/app.css
    ),
    cd: Path.expand("../assets", __DIR__)
  ]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"

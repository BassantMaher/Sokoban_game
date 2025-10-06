import Config

# Production configuration for multi-user Sokoban platform

# Helper function for environment variables
get_env_bool = fn key, default ->
  case System.get_env(key) do
    nil -> default
    "true" -> true
    "1" -> true
    "yes" -> true
    "on" -> true
    _ -> false
  end
end

get_env_int = fn key, default ->
  case System.get_env(key) do
    nil -> default
    value -> String.to_integer(value)
  end
end

# Auth Service production config
config :auth_service, AuthServiceWeb.Endpoint,
  cache_static_manifest: "priv/static/cache_manifest.json",
  server: true,
  force_ssl: get_env_bool.("FORCE_SSL", true)

# Game Service production config
config :game_service, GameServiceWeb.Endpoint,
  cache_static_manifest: "priv/static/cache_manifest.json",
  server: true,
  force_ssl: get_env_bool.("FORCE_SSL", true)

# Database production config
config :sokoban_task2, SokobanTask2.Repo,
  ssl: get_env_bool.("DATABASE_SSL", true),
  pool_size: get_env_int.("DATABASE_POOL_SIZE", 20)

# Do not print debug messages in production
config :logger, level: :info

# Runtime production configuration, including reading
# of environment variables, is done on config/runtime.exs.

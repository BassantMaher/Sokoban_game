import Config

# Test environment configuration

# Configure database for tests
config :sokoban_task2, SokobanTask2.Repo,
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: 10

# Auth Service test config
config :auth_service, AuthServiceWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4011],
  secret_key_base: System.get_env("SECRET_KEY_BASE") || "crAbJlBJ2kN9Sd9BSXnkGgkmi0hdSCVB+H7a3mOk4WN1ADuJlkB2AG/3biBqKbbxbJBKDLASNZsmdkjk45nqwkjnefij",
  server: false

# Game Service test config
config :game_service, GameServiceWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4010],
  secret_key_base: System.get_env("SECRET_KEY_BASE") || "crAbJlBJ2kN9Sd9BSXnkGgkmi0hdSCVB+H7a3mOk4WN1ADuJlkB2AG/3biBqKbbxbJBKDLASNZsmdkjk45nqwkjnefij",
  server: false

# Disable authentication for testing
config :auth_service, AuthService.Guardian,
  secret_key: System.get_env("JWT_SECRET_KEY") || "test-jwt-secret-key-for-testing-environment-64-characters-long",
  ttl: {1, :day}

# Print only warnings and errors during test
config :logger, level: :warning

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime

import Config

# Helper function to get environment variable with fallback
get_env = fn key, default -> System.get_env(key) || default end
get_env_int = fn key, default ->
  case System.get_env(key) do
    nil -> default
    value -> String.to_integer(value)
  end
end

# Database configuration for development
config :sokoban_task1, SokobanTask1.Repo,
  stacktrace: true,
  show_sensitive_data_on_connection_error: true

# For development, we disable any cache and enable
# debugging and code reloading.
#
# The watchers configuration can be used to run external
# watchers to your application. For example, we can use it
# to bundle .js and .css sources.
config :sokoban_task1, SokobanTask1Web.Endpoint,
  # Binding to loopback ipv4 address prevents access from other machines.
  # Change to `ip: {0, 0, 0, 0}` to allow access from other machines.
  http: [ip: {127, 0, 0, 1}, port: get_env_int.("PHX_PORT", 4000)],
  check_origin: false,
  code_reloader: true,
  debug_errors: true,
  secret_key_base: get_env.("SECRET_KEY_BASE", "very_long_secret_key_base_for_development_that_is_definitely_longer_than_64_bytes_and_suitable_for_cookie_encryption"),
  watchers: [
    esbuild: {Esbuild, :install_and_run, [:sokoban_task1, ~w(--sourcemap=inline --watch)]},
    tailwind: {Tailwind, :install_and_run, [:sokoban_task1, ~w(--watch)]}
  ]

# Watch static and templates for browser reloading.
config :sokoban_task1, SokobanTask1Web.Endpoint,
  live_reload: [
    patterns: [
      ~r"priv/static/(?!uploads/).*(js|css|png|jpeg|jpg|gif|svg)$",
      ~r"priv/gettext/.*(po)$",
      ~r"lib/sokoban_task1_web/(controllers|live|components)/.*(ex|heex)$"
    ]
  ]

# Enable dev routes for dashboard and mailbox
config :sokoban_task1, dev_routes: true

# Do not include metadata nor timestamps in development logs
config :logger, :console, format: "[$level] $message\n"

# Set a higher stacktrace during development. Avoid configuring such
# in production as building large stacktraces may be expensive.
config :phoenix, :stacktrace_depth, 20

# Initialize plugs at runtime for faster development compilation
config :phoenix, :plug_init_mode, :runtime

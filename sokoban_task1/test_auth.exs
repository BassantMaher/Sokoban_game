#!/usr/bin/env elixir

# Test authentication
alias SokobanTask1.{Repo, Accounts}
alias SokobanTask1.Accounts.User

# Start the Repo
Application.put_env(:sokoban_task1, SokobanTask1.Repo,
  database: "sokoban_task1_dev",
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  show_sensitive_data_on_connection_error: true,
  pool_size: 10
)

{:ok, _} = Application.ensure_all_started(:ecto_sql)
{:ok, _} = Application.ensure_all_started(:postgrex)
{:ok, _} = SokobanTask1.Repo.start_link()

# Check users
users = Repo.all(User)
IO.puts("Found #{length(users)} users:")

Enum.each(users, fn user ->
  IO.puts("  Email: #{user.email}")
  IO.puts("  Username: #{user.username}")
  IO.puts("  Password hash: #{String.slice(user.password_hash || "nil", 0, 30)}...")
  IO.puts("  Is admin: #{user.is_admin}")
  IO.puts("  ---")
end)

# Test authentication with a common password
if length(users) > 0 do
  user = Enum.at(users, 0)
  IO.puts("Testing authentication with user: #{user.email}")

  # Test with wrong password
  case Accounts.authenticate_user(user.email, "wrongpassword") do
    {:ok, _} -> IO.puts("❌ Wrong password accepted!")
    {:error, :invalid_credentials} -> IO.puts("✅ Wrong password correctly rejected")
  end

  # Test with right password (if we know it)
  test_passwords = ["password", "123456", "admin", "test", "password123"]

  Enum.each(test_passwords, fn password ->
    case Accounts.authenticate_user(user.email, password) do
      {:ok, _} -> IO.puts("✅ Password '#{password}' works!")
      {:error, :invalid_credentials} -> IO.puts("❌ Password '#{password}' doesn't work")
    end
  end)
end

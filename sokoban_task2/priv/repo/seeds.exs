alias SokobanTask2.Repo
alias AuthService.Accounts.{Role, User, Level}

# Create roles
{:ok, anonymous_role} = Repo.insert!(%Role{name: "anonymous"})
{:ok, player_role} = Repo.insert!(%Role{name: "player"})
{:ok, admin_role} = Repo.insert!(%Role{name: "admin"})

IO.puts("Created roles: anonymous, player, admin")

# Create admin user
admin_attrs = %{
  email: System.get_env("ADMIN_EMAIL") || "admin@example.com",
  name: System.get_env("ADMIN_NAME") || "Admin User",
  password: System.get_env("ADMIN_PASSWORD") || "password",
  role_id: admin_role.id
}

{:ok, admin_user} = %User{}
|> User.changeset(admin_attrs)
|> Repo.insert()

IO.puts("Created admin user: admin@example.com / password")

# Create sample levels
level1_board = [
  "############",
  "#@         #",
  "# $$ ## $$ #",
  "#  .  .  . #",
  "## ### ### #",
  "#  $  $  $ #",
  "#  .  .  . #",
  "# $$ ## $$ #",
  "#    ..    #",
  "############"
]

level1_attrs = %{
  name: "Challenge Level 1",
  board_json: Jason.encode!(level1_board),
  width: 12,
  height: 10,
  creator_id: admin_user.id
}

{:ok, _level1} = %Level{}
|> Level.changeset(level1_attrs)
|> Repo.insert()

level2_board = [
  "##########",
  "#@  .    #",
  "# $  $   #",
  "#   .$ . #",
  "#  $ $   #",
  "#    .   #",
  "##########"
]

level2_attrs = %{
  name: "Simple Level 2",
  board_json: Jason.encode!(level2_board),
  width: 10,
  height: 7,
  creator_id: admin_user.id
}

{:ok, _level2} = %Level{}
|> Level.changeset(level2_attrs)
|> Repo.insert()

level3_board = [
  "########",
  "#@  .  #",
  "# $ $  #",
  "#  .   #",
  "# $ $  #",
  "#  . . #",
  "########"
]

level3_attrs = %{
  name: "Mini Level 3",
  board_json: Jason.encode!(level3_board),
  width: 8,
  height: 7,
  creator_id: admin_user.id
}

{:ok, _level3} = %Level{}
|> Level.changeset(level3_attrs)
|> Repo.insert()

IO.puts("Created 3 sample levels")
IO.puts("Database seeded successfully!")
IO.puts("")
IO.puts("You can now:")
IO.puts("1. Start both services: mix phx.server")
IO.puts("2. Register as a player at the game service")
IO.puts("3. Login with admin credentials: admin@example.com / password")
IO.puts("4. Play levels and view leaderboard")
IO.puts("")
IO.puts("Auth Service: http://localhost:4001/api")
IO.puts("Game Service: http://localhost:4000")

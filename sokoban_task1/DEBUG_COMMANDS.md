# Debug Commands for Score System

## 1. Test Score Saving Directly
Run this to test if the score saving function works:
```bash
cd sokoban_task1
mix run test_score_save.exs
```

This will:
- Check if you have users and levels
- Attempt to save a test score
- Show any errors
- Display all scores in database

## 2. Check All Users
```bash
mix run -e "
alias SokobanTask1.{Repo, Accounts.User}
users = Repo.all(User)
IO.puts(\"Total users: #{length(users)}\")
Enum.each(users, fn user ->
  IO.puts(\"  - #{user.email} (ID: #{user.id}, Role: #{user.role})\")
end)
"
```

## 3. Check All Levels
```bash
mix run -e "
alias SokobanTask1.{Repo, Levels.Level}
levels = Repo.all(Level)
IO.puts(\"Total levels: #{length(levels)}\")
Enum.each(levels, fn level ->
  IO.puts(\"  - #{level.name} (ID: #{level.id}, Difficulty: #{level.difficulty})\")
end)
"
```

## 4. Check All Scores
```bash
mix run -e "
alias SokobanTask1.{Repo, Scores.Score, Accounts.User, Levels.Level}
scores = Repo.all(Score) |> Repo.preload([:user, :level_record])
IO.puts(\"Total scores: #{length(scores)}\")
Enum.each(scores, fn score ->
  user_email = if score.user, do: score.user.email, else: 'anonymous'
  level_name = if score.level_record, do: score.level_record.name, else: 'unknown'
  IO.puts(\"  - User: #{user_email}, Level: #{level_name}\")
  IO.puts(\"    Time: #{score.time_seconds}s, Moves: #{score.moves}\")
  IO.puts(\"    Completed: #{score.completed_at}\")
end)
"
```

## 5. Manually Save a Test Score
```bash
mix run -e "
alias SokobanTask1.{Repo, Accounts.User, Levels.Level, Scores}

# Get first user and level
user = Repo.all(User) |> List.first()
level = Repo.all(Level) |> List.first()

if user && level do
  IO.puts(\"Saving score for user #{user.email} on level #{level.name}...\")
  case Scores.save_score(user.id, level.id, 100, 40) do
    {:ok, score, status} ->
      IO.puts(\"✅ Success! Status: #{status}\")
      IO.inspect(score)
    {:error, changeset} ->
      IO.puts(\"❌ Failed!\")
      IO.inspect(changeset.errors)
  end
else
  IO.puts(\"❌ No user or level found\")
end
"
```

## 6. Check if Migrations Are Run
```bash
mix ecto.migrations
```

Should show:
```
up     20250107000001  create_users
up     20250107000002  create_scores
up     20250107000003  create_levels
up     20250107000004  update_scores_with_level_id
```

## 7. Drop and Recreate Database (DANGER - Deletes all data!)
```bash
mix ecto.drop
mix ecto.create
mix ecto.migrate
mix run priv/repo/seeds.exs
```

## 8. Watch Server Logs in Real-Time
When you complete a level in the game, watch for:
```
=== SAVE SCORE DEBUG ===
Current User: %User{...}
Is Anonymous: false
Level ID: 1
Time: 45
Moves: 20
========================
```

## Troubleshooting Steps

### If no scores are being saved:

1. **Check terminal output when winning a level**
   - Look for "=== SAVE SCORE DEBUG ==="
   - Check if "Current User" is nil or has data
   - Check if "Is Anonymous" is true

2. **Verify you're logged in**
   - Look at the navbar in the game
   - Should show your email address, not "Playing as Anonymous"

3. **Check if user is in session**
   - Restart server: `mix phx.server`
   - Login again
   - Try completing a level

4. **Test score saving directly**
   - Run: `mix run test_score_save.exs`
   - This bypasses the UI and tests the function directly

5. **Check database connection**
   - Run: `mix ecto.migrations`
   - Should show all migrations as "up"

### If "Current User: nil" in debug output:

1. **Logout and login again**
2. **Clear browser cookies**
3. **Check session in database** (if using database sessions)
4. **Restart the server**

### If error "relation does not exist":

Run migrations:
```bash
mix ecto.migrate
```

### If "no such table: users" or similar:

Database needs to be created:
```bash
mix ecto.create
mix ecto.migrate
mix run priv/repo/seeds.exs
```

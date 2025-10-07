# Score Saving Fix - Always Save Scores

## Changes Made

### 1. **New Function: `save_score/4` - Always Saves**

Added a new function in `lib/sokoban_task1/scores.ex` that **always saves every completion** to the database:

```elixir
def save_score(user_id, level_id, time_seconds, moves)
```

**Behavior:**
- ✅ **Always creates a new score record** in the database
- ✅ Returns `{:ok, score, :new_best}` if it's your best score
- ✅ Returns `{:ok, score, :not_best}` if saved but not your best
- ✅ Keeps **full history** of all attempts

**Old function `save_if_best/4`** is still available but only saves if it's better than your previous best.

### 2. **Enhanced User Detection**

Updated `mount/3` in `lib/sokoban_task1_web/live/game_live.ex`:

```elixir
# Now checks BOTH socket assigns AND session for user
current_user = case socket.assigns[:current_user] do
  nil ->
    # Try to load from session as fallback
    case session["user_id"] do
      nil -> nil
      user_id -> SokobanTask1.Accounts.get_user!(user_id)
    end
  user -> user
end
```

**Why this helps:**
- Sometimes the user is in the session but not yet in socket assigns
- This ensures we **always** find the logged-in user

### 3. **Debug Logging**

Added comprehensive debug output to help diagnose issues:

**On Mount:**
```
=== MOUNT DEBUG ===
Session: %{"user_id" => 1, ...}
Current User (after load): %User{id: 1, email: "..."}
Is Anonymous: false
===================
```

**On Win:**
```
=== SAVE SCORE DEBUG ===
Current User: %User{id: 1, email: "test@example.com"}
Is Anonymous: false
Level ID: 2
Time: 65
Moves: 23
========================

✅ Score saved as NEW BEST!
```

**Or if score not saved:**
```
⚠️ Score NOT saved: No user logged in
```

### 4. **Better Error Messages**

Updated flash messages to show **why** a score wasn't saved:

- "Score not saved - Playing as anonymous"
- "Score not saved - No user logged in"
- "Score not saved - No level ID"

### 5. **Updated `save_score_on_win/1`**

Now uses the new `save_score/4` function that **always saves**:

```elixir
case SokobanTask1.Scores.save_score(user.id, game.level_id, elapsed_time, game.moves) do
  {:ok, score, :new_best} ->
    # Saved as new best!
  {:ok, score, :not_best} ->
    # Saved but not best
  {:error, changeset} ->
    # Error - shows in logs
end
```

## How to Test

### 1. Restart the Server

Stop the current server (Ctrl+C) and restart:

```bash
cd sokoban_task1
mix phx.server
```

### 2. Check the Terminal Output

When you load the game page, you should see:
```
=== MOUNT DEBUG ===
Session: %{"_csrf_token" => "...", "user_id" => 1}
...
Current User (after load): %SokobanTask1.Accounts.User{id: 1, email: "..."}
Is Anonymous: false
===================
```

**Important:** Check if `Current User` shows a user or `nil`

### 3. Complete a Level

Play and complete any level. Watch the terminal for:

```
=== SAVE SCORE DEBUG ===
Current User: %SokobanTask1.Accounts.User{...}
Is Anonymous: false
Level ID: 2
Time: 45
Moves: 20
========================

✅ Score saved as NEW BEST!
```

### 4. Check Database

Verify the score was saved:

```bash
cd sokoban_task1
mix run -e "
  alias SokobanTask1.{Repo, Scores.Score, Accounts.User, Levels.Level}
  
  Score
  |> Repo.all()
  |> Repo.preload([:user, :level_record])
  |> Enum.each(fn score ->
    IO.puts(\"📊 Score ID: #{score.id}\")
    IO.puts(\"   User: #{score.user.email}\")
    IO.puts(\"   Level: #{score.level_record.name}\")
    IO.puts(\"   Time: #{div(score.time_seconds, 60)}:#{String.pad_leading(to_string(rem(score.time_seconds, 60)), 2, \"0\")}\")
    IO.puts(\"   Moves: #{score.moves}\")
    IO.puts(\"   Completed: #{score.completed_at}\")
    IO.puts(\"\")
  end)
"
```

## Troubleshooting

### Problem: "Score NOT saved: No user logged in"

**Solution:**
1. Make sure you're logged in (not playing as anonymous)
2. Check terminal output for "Current User: nil"
3. Try logging out and logging back in
4. Clear browser cookies and login again

### Problem: "Score NOT saved: Playing as anonymous"

**Solution:**
- You're playing as anonymous user
- Logout and login with a real account
- Scores are only saved for logged-in users

### Problem: Terminal shows "Current User: nil"

**Solution:**
1. Check if you're actually logged in (look at the navbar)
2. Try this command to check session:
   ```elixir
   # In browser console
   localStorage.clear()
   # Then refresh page and login again
   ```

### Problem: No debug output in terminal

**Solution:**
- Make sure you restarted the server after the code changes
- The debug output only appears when connected via WebSocket (not on initial page load)

## Database Schema

Every score now includes:

```elixir
%Score{
  id: 1,
  user_id: 1,              # ← Links to user
  level_id: 2,             # ← Links to level
  time_seconds: 65,        # ← Time in seconds
  moves: 23,               # ← Number of moves
  completed_at: ~U[...],   # ← When completed
  inserted_at: ~U[...],    # ← When record created
  updated_at: ~U[...]      # ← When last updated
}
```

## Benefits of Always Saving

1. **Full History**: See all your attempts, not just the best
2. **Progress Tracking**: Track improvement over time
3. **Statistics**: Calculate average time, moves, etc.
4. **No Lost Data**: Every completion is recorded
5. **Easier Debugging**: Can see if scores are being saved at all

## Next Steps

After testing, if everything works:

1. **Remove debug logging** (optional) - the `IO.puts` statements
2. **Add score history page** - show all attempts for a user
3. **Add statistics** - average time, total completions, etc.
4. **Add graphs** - visualize improvement over time

---

**Test it now!** 🎮
1. Restart server: `mix phx.server`
2. Login
3. Complete a level
4. Check terminal output
5. Verify database

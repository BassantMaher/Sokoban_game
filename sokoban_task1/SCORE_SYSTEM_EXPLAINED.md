# Score System - How It Works

## ✅ Current Implementation Status

Your Sokoban game **already has a complete score tracking system** that saves both **time and moves** to the database when a user wins a level!

## How Score Saving Works

### 1. When User Wins a Level

When all boxes are on goals, the `Game.move/2` function detects the win and sets `won: true` in the game state.

**File**: `lib/sokoban_task1_web/live/game_live.ex`
```elixir
def handle_event("move", %{"direction" => direction}, socket) do
  # ... game logic ...
  
  # If game just won, save the score
  socket =
    if not old_game.won and new_game.won do
      save_score_on_win(socket)  # ← This saves the score!
    else
      socket
    end
  
  {:noreply, socket}
end
```

### 2. Score Saving Logic

**File**: `lib/sokoban_task1_web/live/game_live.ex` (line ~288)
```elixir
defp save_score_on_win(socket) do
  game = socket.assigns.game
  user = socket.assigns.current_user
  is_anonymous = socket.assigns[:anonymous] || false
  elapsed_time = socket.assigns.elapsed_time  # ← Time in seconds
  
  # Only save if user is logged in (not anonymous) and level_id exists
  if !is_anonymous && user != nil && game.level_id != nil do
    # This function saves both time AND moves to database
    case SokobanTask1.Scores.save_if_best(
      user.id, 
      game.level_id, 
      elapsed_time,    # ← Time saved here
      game.moves       # ← Moves saved here
    ) do
      {:ok, %SokobanTask1.Scores.Score{} = score} ->
        # New best score!
        socket
        |> assign(:best_score, score)
        |> put_flash(:info, "🎉 New best score! Time: #{format_time(elapsed_time)}, Moves: #{game.moves}")
      
      {:ok, :not_best} ->
        # Completed but not your best
        put_flash(socket, :info, "🎉 Level completed! (Not your best score)")
      
      {:error, _} ->
        # Error saving
        put_flash(socket, :error, "Failed to save score.")
    end
  else
    # Anonymous user - no save
    put_flash(socket, :info, "🎉 You won! Time: #{format_time(elapsed_time)}, Moves: #{game.moves}")
  end
end
```

### 3. Database Save Function

**File**: `lib/sokoban_task1/scores.ex`
```elixir
def save_if_best(user_id, level_id, time_seconds, moves) do
  case get_user_best_score(user_id, level_id) do
    nil ->
      # No previous score, save this one
      create_score(%{
        user_id: user_id,
        level_id: level_id,
        time_seconds: time_seconds,  # ← Time saved to DB
        moves: moves,                 # ← Moves saved to DB
        completed_at: DateTime.utc_now()
      })
    
    best_score ->
      # Compare with previous best
      if is_better_score?(time_seconds, moves, best_score.time_seconds, best_score.moves) do
        # New score is better, save it
        create_score(%{
          user_id: user_id,
          level_id: level_id,
          time_seconds: time_seconds,  # ← Better time saved
          moves: moves,                 # ← Better moves saved
          completed_at: DateTime.utc_now()
        })
      else
        # Not better, don't save
        {:ok, :not_best}
      end
  end
end
```

### 4. Database Schema

**File**: `lib/sokoban_task1/scores/score.ex`
```elixir
schema "scores" do
  field :level, :integer              # Legacy field
  field :time_seconds, :integer       # ← Time stored here
  field :moves, :integer              # ← Moves stored here
  field :completed_at, :utc_datetime  # When completed
  
  belongs_to :user, SokobanTask1.Accounts.User
  belongs_to :level_record, SokobanTask1.Levels.Level, foreign_key: :level_id
  
  timestamps(type: :utc_datetime)
end
```

## What Gets Saved to Database

Every time a **logged-in user** wins a level (and it's their best score), a new record is created in the `scores` table with:

| Field | Value | Example |
|-------|-------|---------|
| `user_id` | User's database ID | `1` |
| `level_id` | Level's database ID | `2` |
| `time_seconds` | Time in seconds | `125` (2 min 5 sec) |
| `moves` | Number of moves | `47` |
| `completed_at` | Timestamp of completion | `2025-10-07 10:45:23` |
| `inserted_at` | Record created timestamp | `2025-10-07 10:45:23` |

## Score Comparison Logic

A new score is considered **better** if:
1. **Time is lower** (faster completion), OR
2. **Same time but fewer moves**

**Example**:
- Best score: 2:00 (120 sec), 50 moves
- New score: 1:55 (115 sec), 60 moves → **BETTER** (faster time)
- New score: 2:00 (120 sec), 45 moves → **BETTER** (same time, fewer moves)
- New score: 2:05 (125 sec), 40 moves → **NOT BETTER** (slower time)

## Testing Score Saving

### Test 1: First Completion
1. **Login** (not anonymous)
2. **Select Level 2** (easy level)
3. **Complete the level**
4. **Result**: You should see "🎉 New best score! Time: X:XX, Moves: XX"

### Test 2: Verify Database Save
After completing a level, check the database:

```bash
cd sokoban_task1
mix run -e "alias SokobanTask1.{Repo, Scores.Score}; Repo.all(Score) |> IO.inspect()"
```

You should see output like:
```elixir
[
  %SokobanTask1.Scores.Score{
    id: 1,
    user_id: 1,
    level_id: 2,
    time_seconds: 65,
    moves: 23,
    completed_at: ~U[2025-10-07 10:45:23Z],
    ...
  }
]
```

### Test 3: Beat Your Score
1. **Reset the level**
2. **Complete it faster or with fewer moves**
3. **Result**: "🎉 New best score!" message again

### Test 4: Worse Score
1. **Reset the level**
2. **Take longer or use more moves**
3. **Result**: "🎉 Level completed! (Not your best score)"
4. **Database**: No new record created (old best remains)

### Test 5: Anonymous User
1. **Logout** and **Play as Anonymous**
2. **Complete a level**
3. **Result**: Win message shown but NO database save

## Viewing Saved Scores

### Via Database Query
```bash
cd sokoban_task1
mix run -e "
  alias SokobanTask1.{Repo, Scores.Score, Accounts.User, Levels.Level}
  
  Score
  |> Repo.all()
  |> Repo.preload([:user, :level_record])
  |> Enum.each(fn score ->
    IO.puts(\"User: #{score.user.email}\")
    IO.puts(\"Level: #{score.level_record.name}\")
    IO.puts(\"Time: #{div(score.time_seconds, 60)}:#{rem(score.time_seconds, 60)}\")
    IO.puts(\"Moves: #{score.moves}\")
    IO.puts(\"---\")
  end)
"
```

### Via IEx Console
```bash
cd sokoban_task1
iex -S mix phx.server
```

Then in IEx:
```elixir
# Get all scores for user ID 1
SokobanTask1.Scores.list_user_all_scores(1)

# Get best score for user 1 on level 2
SokobanTask1.Scores.get_user_best_score(1, 2)

# Get leaderboard for level 2
SokobanTask1.Scores.get_leaderboard(2)
```

## Database Table Structure

**Table**: `scores`

| Column | Type | Description |
|--------|------|-------------|
| `id` | integer | Primary key |
| `user_id` | integer | Foreign key to users table |
| `level_id` | integer | Foreign key to levels table |
| `level` | integer | Legacy field (not used with new system) |
| `time_seconds` | integer | Completion time in seconds |
| `moves` | integer | Number of moves taken |
| `completed_at` | timestamp | When the level was completed |
| `inserted_at` | timestamp | When record was created |
| `updated_at` | timestamp | When record was last updated |

## Additional Features Available

### 1. User's Best Score Display
Already implemented! Shows at the top of the game:
```
⭐ Best: 2:05 (47 moves)
```

### 2. Leaderboard (Future Feature)
The `get_leaderboard/2` function is ready to use:
```elixir
# Get top 10 scores for level 2
SokobanTask1.Scores.get_leaderboard(2, 10)
```

### 3. User Rank (Future Feature)
The `get_user_rank/2` function is ready:
```elixir
# Get user's rank on level 2
SokobanTask1.Scores.get_user_rank(1, 2)  # Returns: 1, 2, 3, etc.
```

### 4. Score History
View all attempts for a user on a specific level:
```elixir
SokobanTask1.Scores.list_user_scores(user_id, level_id)
```

## Summary

✅ **Score saving is fully implemented and working!**

When a logged-in user wins a level:
1. ✅ Timer value (in seconds) is saved to `time_seconds` field
2. ✅ Move count is saved to `moves` field
3. ✅ Only saves if it's the user's best score for that level
4. ✅ Shows appropriate success/completion message
5. ✅ Updates the "Best Score" display immediately

**No additional code changes needed** - just test it by completing a level!

---

**Ready to test?** 🎮
1. Start the server: `mix phx.server`
2. Login (or register)
3. Complete any level
4. Check the success message and database!

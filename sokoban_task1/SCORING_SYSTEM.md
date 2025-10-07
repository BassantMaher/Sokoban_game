# Scoring System Implementation

## Overview
Complete scoring system with timer, move counter, and database persistence that only saves the best scores.

## Features Implemented

### 1. Score Schema & Database
- **Table**: `scores`
- **Fields**:
  - `user_id` - Links to user (nullable for future anonymous scoring)
  - `level` - Game level number
  - `time_seconds` - Time taken to complete
  - `moves` - Number of moves made
  - `completed_at` - Timestamp of completion
- **Indexes**: Optimized for queries by user, level, and best scores

### 2. Score Context (`lib/sokoban_task1/scores.ex`)
- `save_if_best/4` - Only saves if score is better than previous best
- `get_user_best_score/2` - Gets user's best score for a level
- `get_leaderboard/2` - Gets top N scores for a level
- `get_user_rank/2` - Gets user's ranking for a level
- Comparison logic: Lower time wins, moves as tiebreaker

### 3. Game Module Updates
- Added `moves` field to track move count
- Added `level` field to identify which level
- `increment_moves/1` - Increments counter on each valid move
- Counter increments on both regular moves and box pushes

### 4. GameLive Updates
- **Timer**: Starts on mount, updates every second
- **Move Counter**: Displays current moves
- **Best Score Display**: Shows user's best time/moves if exists
- **Auto-save**: When game is won, automatically saves score (only if better)
- **Reset**: Resets timer and move counter
- **Flash Messages**: 
  - "New best score!" when beating previous best
  - "Not your best" when score isn't better
  - Anonymous users see completion message without save

### 5. UI Improvements
- **Stats Bar**: Shows Time, Moves, and Best Score
- **Live Timer**: Updates every second during gameplay
- **Win Message**: Enhanced with completion stats
- **Best Score Indicator**: Gold trophy if current score is the best

## How It Works

### Scoring Algorithm
```
Better score if:
1. Time is lower, OR
2. Time is equal AND moves are lower
```

### Data Flow
1. User starts playing → Timer starts, moves = 0
2. User makes move → Moves increment
3. User wins → Check if score is better than previous best
4. If better → Save to database, update best score display
5. If not better → Show message, don't save

### Anonymous vs Authenticated
- **Authenticated Users**: Scores saved to database, best score tracked
- **Anonymous Users**: Can play but scores NOT saved (flash message only)

## Setup Instructions

### 1. Run the new migration
```cmd
cd d:\bassant\Freelancing\sokoban-game\sokoban_task1
mix ecto.migrate
```

### 2. Restart the server
```cmd
mix phx.server
```

### 3. Test the system
1. Register and login as a user
2. Play the game and complete it
3. Note your time and moves
4. Reset and play again
5. Try to beat your previous score!

## Database Schema

```sql
CREATE TABLE scores (
  id SERIAL PRIMARY KEY,
  user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
  level INTEGER NOT NULL,
  time_seconds INTEGER NOT NULL,
  moves INTEGER NOT NULL,
  completed_at TIMESTAMP NOT NULL,
  inserted_at TIMESTAMP NOT NULL,
  updated_at TIMESTAMP NOT NULL
);

CREATE INDEX scores_user_id_index ON scores (user_id);
CREATE INDEX scores_level_index ON scores (level);
CREATE INDEX scores_user_id_level_index ON scores (user_id, level);
CREATE INDEX scores_level_time_seconds_moves_index ON scores (level, time_seconds, moves);
```

## Future Enhancements

### Leaderboard Page
Create a separate LiveView to show:
- Top 10 players for each level
- User's rank
- Global statistics

### Multiple Levels
- Add level selection dropdown
- Track best scores per level
- Unlock levels based on completion

### Score History
- Show all attempts, not just best
- Graph of improvement over time
- Statistics (average time, total games, etc.)

### Achievements
- Speed runner: Complete under X seconds
- Efficient player: Complete in minimum moves
- Persistent: 100 games played

## API Examples

### Check User's Best Score
```elixir
# In IEx
SokobanTask1.Scores.get_user_best_score(user_id, level)
```

### Get Leaderboard
```elixir
# Top 10 for level 1
SokobanTask1.Scores.get_leaderboard(1, 10)
```

### Get User's Rank
```elixir
# What place is user in?
SokobanTask1.Scores.get_user_rank(user_id, level)
```

### Manually Save Score
```elixir
SokobanTask1.Scores.save_if_best(user_id, level, time_seconds, moves)
```

## Testing

### Create Test Scores
```elixir
# In IEx after starting: iex -S mix phx.server
alias SokobanTask1.{Accounts, Scores}

# Create a user
{:ok, user} = Accounts.register_user(%{
  email: "player@example.com",
  password: "password123",
  role: "user"
})

# Save some scores
Scores.save_if_best(user.id, 1, 120, 50)  # 2 minutes, 50 moves
Scores.save_if_best(user.id, 1, 90, 45)   # Better! 1:30, 45 moves
Scores.save_if_best(user.id, 1, 150, 40)  # Worse time, won't save

# Check best
Scores.get_user_best_score(user.id, 1)
```

## Notes

- Timer stops when game is won
- Score is saved automatically on win
- Only saves if it's better than previous best
- Anonymous users can play but scores are not persisted
- Move counter includes both player moves and box pushes
- All times stored in seconds (integer)
- UI shows formatted time (MM:SS)

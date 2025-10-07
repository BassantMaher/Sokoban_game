# Level System Testing Guide

## Overview
The Sokoban game now includes a complete level system with:
- ✅ Database storage for levels (PostgreSQL)
- ✅ 10 pre-designed levels (Easy to Expert difficulty)
- ✅ Level selection dropdown UI
- ✅ Score tracking per level
- ✅ Best score display for each level

## Setup Instructions

### 1. Run Database Migrations

Make sure your PostgreSQL database is running, then execute:

```bash
cd sokoban_task1
mix ecto.migrate
```

This will create the following tables:
- `users` - User authentication
- `scores` - Score tracking with user_id and level_id
- `levels` - Game levels with board data
- Update scores table with level_id foreign key

### 2. Seed the Database

Populate the database with 10 levels:

```bash
mix run priv/repo/seeds.exs
```

You should see:
```
✅ Seeded 10 levels successfully!
```

### 3. Start the Server

```bash
mix phx.server
```

Visit: http://localhost:4000

## Testing the Level System

### Test 1: Level Selection
1. **Login or Play as Anonymous**
2. **Find the Level Selection Dropdown** (at the top of the game board)
3. **Select Different Levels**:
   - Level 1: "Classic Challenge" (Medium)
   - Level 2: "First Steps" (Easy)
   - Level 3: "Corner Challenge" (Easy)
   - Level 4: "The Warehouse" (Medium)
   - Level 5: "The Maze" (Medium)
   - Level 6: "Precision Master" (Hard)
   - Level 7: "The Cross" (Hard)
   - Level 8: "The Spiral" (Expert)
   - Level 9: "The Tower" (Expert)
   - Level 10: "Master's Final Test" (Expert)

4. **Verify**:
   - Game board updates immediately
   - Level name displays below the dropdown
   - Timer resets to 0:00
   - Moves counter resets to 0
   - Best score updates (if you have a saved score for that level)

### Test 2: Score Saving (Logged-in Users Only)
1. **Register a new account** or **login**
2. **Select a level** (e.g., Level 2 - Easy)
3. **Complete the level** by pushing all boxes to goals
4. **Verify Success Message**:
   - "🎉 New best score! Time: X:XX, Moves: XX"
5. **Reset and play again with a worse score**:
   - Click "Reset" button
   - Complete the level slower or with more moves
   - You should see: "Level completed! But not your best score yet."
6. **Reset and beat your score**:
   - Complete the level faster or with fewer moves
   - You should see: "🎉 New best score!" again

### Test 3: Anonymous Play
1. **Logout** if logged in
2. **Click "Play as Anonymous"** on the welcome page
3. **Play any level**
4. **Complete the level**
5. **Verify**:
   - You see: "Level completed! Time: X:XX, Moves: XX"
   - No "New best score" message (scores not saved for anonymous users)
   - Best score section does NOT display

### Test 4: Best Score Display
1. **Login with an account**
2. **Complete a level** (e.g., Level 2)
3. **Select a different level** (e.g., Level 3)
4. **Come back to Level 2**
5. **Verify**:
   - Your previous best score displays: "⭐ Best: X:XX (XX moves)"

### Test 5: Reset Button
1. **Start playing any level**
2. **Make some moves**
3. **Click "Reset" button**
4. **Verify**:
   - Board resets to starting position
   - Timer resets to 0:00
   - Moves counter resets to 0
   - Same level remains selected

## Level Descriptions

### Easy Levels (Good for beginners)
- **Level 2: First Steps** - 7x7 grid, 4 boxes, symmetric layout
- **Level 3: Corner Challenge** - 8x8 grid, 4 boxes, corner pushing practice

### Medium Levels (Moderate difficulty)
- **Level 1: Classic Challenge** - 12x10 grid, 9 boxes, the original game board
- **Level 4: The Warehouse** - 10x9 grid, 8 boxes, warehouse theme
- **Level 5: The Maze** - 11x9 grid, 6 boxes, maze navigation

### Hard Levels (Requires strategy)
- **Level 6: Precision Master** - 10x7 grid, 4 boxes, precision required
- **Level 7: The Cross** - 11x11 grid, 8 boxes, cross-shaped puzzle

### Expert Levels (Master level challenges)
- **Level 8: The Spiral** - 12x11 grid, 4 boxes, spiral pattern
- **Level 9: The Tower** - 12x9 grid, 8 boxes, tower climbing
- **Level 10: Master's Final Test** - 14x15 grid, 12 boxes, ultimate challenge

## Database Schema

### Levels Table
```elixir
- id (primary key)
- name (string) - e.g., "First Steps"
- difficulty (enum) - :easy, :medium, :hard, :expert
- order (integer) - Display order in dropdown
- description (text) - Level description
- board_data (array of strings) - The game board as string array
- inserted_at, updated_at
```

### Scores Table
```elixir
- id (primary key)
- user_id (foreign key to users)
- level_id (foreign key to levels) - Links score to specific level
- time_seconds (integer) - Completion time
- moves (integer) - Number of moves
- completed_at (datetime)
```

## Score Logic
- **Saves only if better**: New score is saved only if:
  1. It's faster (lower time_seconds), OR
  2. Same time but fewer moves
- **Per-level tracking**: Each level has its own best score
- **Logged-in only**: Anonymous users can play but scores aren't saved
- **Automatic**: Scores save automatically when you win a level

## Troubleshooting

### Error: "relation 'levels' does not exist"
**Solution**: Run `mix ecto.migrate`

### Error: "No levels in dropdown"
**Solution**: Run `mix run priv/repo/seeds.exs`

### Error: "Failed to load level"
**Possible causes**:
1. Database not seeded → Run seeds file
2. Database connection issue → Check `config/dev.exs`
3. Migration not run → Run `mix ecto.migrate`

### Dropdown doesn't change level
**Solution**: 
1. Check browser console for errors
2. Make sure JavaScript is enabled
3. Verify LiveView connection is active (should see green dot in browser)

### Score not saving
**Possible causes**:
1. Playing as anonymous → Login to save scores
2. Didn't complete the level → All boxes must be on goals
3. Score not better than previous → Check "Best" display

## Next Steps

### Adding More Levels
Edit `priv/repo/seeds.exs` and add:

```elixir
{:ok, _level} = Repo.insert(%Level{
  name: "Your Level Name",
  difficulty: "easy", # or "medium", "hard", "expert"
  order: 11, # Next order number
  description: "Your description",
  board_data: [
    "########",
    "#@  $. #",
    "########"
  ]
})
```

Then run: `mix run priv/repo/seeds.exs`

### Leaderboard (Future Feature)
The system is ready for a leaderboard feature. The scores table already tracks all completions with user_id and level_id.

## Technical Details

### Files Modified
- `lib/sokoban_task1/levels/level.ex` - Level schema
- `lib/sokoban_task1/levels.ex` - Levels context
- `lib/sokoban_task1/scores/score.ex` - Updated with level_id
- `lib/sokoban_task1/scores.ex` - Score management with level_id
- `lib/sokoban_task1/game.ex` - Added level_id, level_name fields
- `lib/sokoban_task1_web/live/game_live.ex` - Level selection UI
- `priv/repo/migrations/` - 4 migrations for database schema
- `priv/repo/seeds.exs` - 10 levels seeded

### Key Functions
- `Levels.list_levels/0` - Get all levels ordered by order field
- `Levels.get_level!/1` - Get level by ID
- `Game.new_from_level/1` - Create game from Level struct
- `Scores.save_if_best/4` - Save score only if better
- `Scores.get_user_best_score/2` - Get best score for user+level

---

**Happy Gaming! 🎮**

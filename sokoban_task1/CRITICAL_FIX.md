# CRITICAL FIX - Score Saving System

## Problem Identified
The score saving system wasn't working because **the LiveView wasn't properly receiving the user from the session**. Phoenix LiveView requires special handling to pass session data to the LiveView process.

## Root Cause
- The `fetch_current_user` plug sets `conn.assigns.current_user`
- But LiveView runs in a separate process and needs session data passed via `on_mount` hooks
- Without the `on_mount` hook, the user was always `nil` in the LiveView

## Complete Fix Applied

### 1. Created `UserAuth` Module with `on_mount` Hook
**File**: `lib/sokoban_task1_web/user_auth.ex` (NEW)

This module:
- Intercepts LiveView mount process
- Reads `user_id` or `anonymous` from session
- Loads the user from database
- Assigns `current_user` and `anonymous` to the socket
- **Extensive debug logging** to see what's happening

### 2. Updated Router to Use `live_session`
**File**: `lib/sokoban_task1_web/router.ex`

Changed from:
```elixir
live "/game", GameLive
```

To:
```elixir
live_session :authenticated,
  on_mount: {SokobanTask1Web.UserAuth, :mount_current_user} do
  live "/game", GameLive
end
```

This ensures the `on_mount` hook runs BEFORE the LiveView mounts.

### 3. Added `get_user/1` Function
**File**: `lib/sokoban_task1/accounts.ex`

Added non-raising version of `get_user!`:
```elixir
def get_user(id), do: Repo.get(User, id)
```

Returns `nil` if user not found (doesn't raise error).

### 4. Simplified GameLive Mount
**File**: `lib/sokoban_task1_web/live/game_live.ex`

Removed duplicate user loading logic since it's now handled by `on_mount`.

### 5. Fixed Score Schema Validation
**File**: `lib/sokoban_task1/scores/score.ex`

Changed validation to **require** `user_id` and `level_id`:
```elixir
|> validate_required([:user_id, :level_id, :time_seconds, :moves, :completed_at])
```

### 6. Enhanced Score Saving with Debug Logging
**File**: `lib/sokoban_task1/scores.ex`

Added extensive logging to `save_score/4` function:
- Shows data being saved
- Shows if create succeeds or fails
- Shows changeset errors if validation fails

## How to Test

### 1. **Restart the Server** (CRITICAL!)
```bash
# Stop current server (Ctrl+C twice)
cd sokoban_task1
mix phx.server
```

### 2. **Watch Terminal Output**

When you load the game page, you'll see:
```
=== UserAuth.on_mount ===
Session: %{"user_id" => 1, ...}
Found user_id in session: 1
User loaded: user@example.com
Mounted current_user: %User{id: 1, email: "user@example.com"}
Mounted anonymous: false
========================

=== GAME MOUNT ===
Current User: %User{id: 1, ...}
Is Anonymous: false
==================
```

### 3. **Complete a Level**

Play and win. You'll see:
```
=== SAVE SCORE DEBUG ===
Current User: %User{id: 1, ...}
Is Anonymous: false
Level ID: 1
Time: 45
Moves: 20
========================

[Scores.save_score] Attempting to save...
Score data: %{user_id: 1, level_id: 1, time_seconds: 45, moves: 20}
Create score result: {:ok, %Score{id: 1, ...}}
✅ Score created successfully! ID: 1
Status: new_best

✅ Score saved as NEW BEST!
```

### 4. **Verify in Database**
```bash
mix run -e "alias SokobanTask1.{Repo, Scores.Score}; Repo.all(Score) |> IO.inspect()"
```

Should now show scores!

## Debug Flow

### On Page Load:
1. **UserAuth.on_mount** runs FIRST
   - Reads session
   - Loads user
   - Assigns to socket

2. **GameLive.mount** runs SECOND  
   - User already in socket.assigns
   - No need to load again

### On Win:
1. **Game.move** detects win, sets `won: true`
2. **handle_event("move")** calls `save_score_on_win`
3. **save_score_on_win** checks user and calls `Scores.save_score`
4. **Scores.save_score** creates record in database
5. **Flash message** shows success

## Common Issues & Solutions

### Issue: "Current User: nil" in UserAuth.on_mount

**Possible causes:**
1. Not logged in → Login through web interface
2. Session expired → Logout and login again
3. Wrong user_id in session → Check database for user

**Solution:**
```bash
# Check if user exists
mix run -e "alias SokobanTask1.{Repo, Accounts.User}; Repo.all(User) |> IO.inspect()"

# If no users, register through web interface at /register
```

### Issue: "Anonymous: true" when you're logged in

**Solution:**
- Logout completely
- Clear browser cookies
- Login again
- Restart server

### Issue: Changeset errors when saving

**Look for:**
```
❌ Failed to create score
Changeset errors: [user_id: {"can't be blank", ...}]
```

**This means** user is still nil. Check the mount debug output.

### Issue: No debug output at all

**Solution:**
- Server wasn't restarted
- Run: `mix phx.server` again

## Verification Checklist

After restarting server, verify each step:

- [ ] See "UserAuth.on_mount" output
- [ ] "Mounted current_user" shows a user (not nil)
- [ ] "Mounted anonymous" is false
- [ ] See "GAME MOUNT" output
- [ ] Complete a level
- [ ] See "SAVE SCORE DEBUG" with user data
- [ ] See "Score created successfully" message
- [ ] See "Score saved as NEW BEST!" in browser
- [ ] Check database shows the score

## Files Modified

1. ✅ `lib/sokoban_task1_web/user_auth.ex` - NEW
2. ✅ `lib/sokoban_task1_web/router.ex` - Added live_session
3. ✅ `lib/sokoban_task1/accounts.ex` - Added get_user/1
4. ✅ `lib/sokoban_task1_web/live/game_live.ex` - Simplified mount
5. ✅ `lib/sokoban_task1/scores/score.ex` - Required user_id, level_id
6. ✅ `lib/sokoban_task1/scores.ex` - Enhanced logging

## Next Steps After Fix Works

Once scores are saving successfully:

1. **Remove debug IO.puts** (optional) - they're helpful but verbose
2. **Test with multiple users** - make sure scores are per-user
3. **Test with different levels** - verify level_id is correct
4. **Check leaderboard queries** - use existing functions

---

## 🚀 START HERE:

**1. Restart server:**
```bash
cd sokoban_task1
mix phx.server
```

**2. Look for this in terminal when you load /game:**
```
=== UserAuth.on_mount ===
Mounted current_user: %User{...}  ← Should NOT be nil!
```

**3. If user is nil:**
- Make sure you're logged in (not anonymous)
- Check if user exists in database
- Logout and login again

**4. Complete a level and watch terminal**

**5. Check database:**
```bash
mix run -e "alias SokobanTask1.{Repo, Scores.Score}; Repo.all(Score) |> IO.inspect()"
```

**This WILL work now!** 🎯

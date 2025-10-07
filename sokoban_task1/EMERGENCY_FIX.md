# Emergency Fix - LiveView Crash

## The Issue
You're seeing "view crashed" which means the LiveView is throwing an error during mount.

## Quick Fix Steps

### Step 1: Check Server Logs
Look at your terminal where `mix phx.server` is running. You should see the actual error message there. It will look something like:

```
[error] GenServer #PID<...> terminating
** (SomeError) actual error message here
```

**Copy that error and let me know what it says.**

### Step 2: Try Simpler Approach

If the error mentions `on_mount` or `UserAuth`, let's temporarily disable it:

**Edit `lib/sokoban_task1_web/router.ex`:**

Change:
```elixir
live_session :authenticated,
  on_mount: {SokobanTask1Web.UserAuth, :mount_current_user} do
  live "/game", GameLive
end
```

To:
```elixir
live "/game", GameLive
```

Then restart server and try again.

### Step 3: If Still Crashing

The crash might be from the mount function itself. Let's add error handling:

**Edit `lib/sokoban_task1_web/live/game_live.ex`:**

Find the `mount` function and wrap it in a try-rescue:

```elixir
@impl true
def mount(_params, _session, socket) do
  try do
    # ... existing code ...
  rescue
    e ->
      IO.puts("ERROR IN MOUNT:")
      IO.inspect(e)
      IO.inspect(__STACKTRACE__)
      {:ok, socket}
  end
end
```

## Most Likely Causes

1. **Missing dependency** - The `on_mount` feature requires specific Phoenix LiveView version
2. **Session data format** - Session might have string keys instead of integer for user_id
3. **Database connection** - Can't load levels or user from database

## Immediate Action

**Run this to check your Phoenix LiveView version:**
```bash
cd sokoban_task1
mix deps | grep phoenix_live_view
```

Should show version `0.20.x` or higher.

## Alternative: Revert to Simple Approach

If the `on_mount` approach is causing too many issues, we can use the simpler plug-based approach that was working before.

**Tell me:**
1. What error shows in the server terminal?
2. What version of phoenix_live_view do you have?
3. Do you want to try the simpler approach instead?

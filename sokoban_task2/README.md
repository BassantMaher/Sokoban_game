# Sokoban Task1

A complete Phoenix LiveView Sokoban game implementation.

## Setup Commands

Since Phoenix might not be installed globally, you can run the project with:

```bash
cd sokoban_task1
mix deps.get
mix phx.server
```

## Game Features

- **Tech Stack**: Elixir 1.15+, Phoenix 1.7+ with LiveView, Tailwind CSS
- **Game Rules**: 
  - Board represented as list of strings (immutable)
  - Symbols: `#` (wall), `@` (player, yellow), `$` (box, red), `.` (goal, green), ` ` (empty, white)
  - Player moves in all 4 directions via WASD or arrow keys
  - Push adjacent box if space behind is empty (no pulling, no pushing multiple boxes)
  - Win condition: All boxes on goals (no loose `$` symbols)

## Architecture (MVC Pattern)

- **Model**: `SokobanTask1.Game` - Pure Elixir struct/logic with immutable state
- **View**: HEEx template in LiveView renders 2D CSS grid 
- **Controller**: `SokobanTask1Web.GameLive` handles events (mount, handle_event for moves/reset)

## File Structure

```
sokoban_task1/
├── lib/sokoban_task1/game.ex              # Model: Game struct, new_level/0, move/2, check_win?/1
├── lib/sokoban_task1_web/live/game_live.ex # Controller + View: mount/3, handle_event/3, render/1
├── lib/sokoban_task1_web/router.ex        # Scope: live "/", GameLive
├── assets/css/app.css                     # Tailwind + custom styles (.wall, .player, etc.)
├── assets/js/app.js                       # LiveView hooks: KeyboardListener for WASD/arrows
├── test/sokoban_task1_web/live/game_live_test.exs # Basic tests
└── config/config.exs                      # Basic setup (no Ecto)
```

## Sample Level

The game includes a simple level:
```
######
#. . #
#.$$.#
#  @ #
######
```

## Key Features

- **Reactive**: Keypress → WebSocket event → Server updates → DOM diff/patch
- **Validation**: Server-side only (prevent cheats), ignores invalid moves
- **Win Detection**: After each move, checks if all `$` are on `.` positions
- **Edge Cases**: Can't push into wall/another box; player can't occupy wall

## Running the Game

1. `mix deps.get` (install dependencies)
2. `mix phx.server` (start server)
3. Open http://localhost:4000
4. Use WASD or Arrow Keys to push boxes to goals
5. Click "Reset Level" to restart

## Challenges Solved

- **Immutable string manipulation**: Used charlists for efficient character swapping
- **Phoenix LiveView keyboard events**: Created JavaScript hook for key capture
- **State management**: Pure functional game state with structs
- **CSS Grid rendering**: Dynamic HEEx template rendering board as grid

The game is fully functional and demonstrates proper MVC separation in a LiveView context.
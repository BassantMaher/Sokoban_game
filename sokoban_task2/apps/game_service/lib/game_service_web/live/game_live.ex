defmodule GameServiceWeb.GameLive do
  use GameServiceWeb, :live_view

  alias GameService.Game

  def mount(_params, _session, socket) do
    # Initialize a new game
    game = GameService.Game.new_default_game()

    {:ok, assign(socket,
      game: game,
      message: "Use WASD or arrow keys to move. Push all boxes ($) onto goals (.) to win!"
    )}
  end

  def handle_event("move", %{"key" => key}, socket) do
    direction = case key do
      k when k in ["ArrowUp", "w", "W"] -> :up
      k when k in ["ArrowDown", "s", "S"] -> :down
      k when k in ["ArrowLeft", "a", "A"] -> :left
      k when k in ["ArrowRight", "d", "D"] -> :right
      _ -> nil
    end

    if direction do
      old_game = socket.assigns.game
      new_game = GameService.Game.move(old_game, direction)

      message = cond do
        new_game.won -> "🎉 Congratulations! You won in #{new_game.moves} moves! Click 'New Game' to play again."
        new_game.moves == 0 -> "Use WASD or arrow keys to move. Push all boxes ($) onto goals (.) to win!"
        true -> "Moves: #{new_game.moves}"
      end

      {:noreply, assign(socket, game: new_game, message: message)}
    else
      {:noreply, socket}
    end
  end

  def handle_event("restart", _params, socket) do
    game = GameService.Game.new_default_game()
    {:noreply, assign(socket, game: game, message: "New game started! Use WASD or arrow keys to move.")}
  end

  def render(assigns) do
    ~H"""
    <div class="game-container" phx-keydown="move" phx-target="window" tabindex="0">
      <div class="game-header">
        <h1>🎯 Sokoban Game</h1>
        <div class="game-stats">
          <span class="moves">Moves: <%= @game.moves %></span>
          <button phx-click="restart" class="restart-btn">🔄 New Game</button>
        </div>
      </div>

      <div class="game-message">
        <%= @message %>
      </div>

      <div class="game-board">
        <%= for {row, y} <- Enum.with_index(@game.board) do %>
          <div class="row">
            <%= for {cell, x} <- Enum.with_index(String.graphemes(row)) do %>
              <div class={"cell #{cell_class(cell, {x, y}, @game.goal_positions)}"}>
                <%= render_cell(cell, {x, y}, @game.goal_positions) %>
              </div>
            <% end %>
          </div>
        <% end %>
      </div>

      <div class="game-instructions">
        <h3>How to Play:</h3>
        <ul>
          <li>🕹️ Use <strong>WASD</strong> or <strong>Arrow Keys</strong> to move</li>
          <li>📦 Push all <strong>boxes ($)</strong> onto <strong>goals (.)</strong></li>
          <li>🎯 Complete the puzzle in the fewest moves possible!</li>
        </ul>
      </div>
    </div>

    <style>
      .game-container {
        max-width: 800px;
        margin: 0 auto;
        padding: 20px;
        font-family: monospace;
        background: linear-gradient(135deg, #1e3c72 0%, #2a5298 100%);
        min-height: 100vh;
        color: white;
      }

      .game-header {
        display: flex;
        justify-content: space-between;
        align-items: center;
        margin-bottom: 20px;
        background: rgba(255, 255, 255, 0.1);
        padding: 15px;
        border-radius: 10px;
      }

      .game-header h1 {
        margin: 0;
        color: #FFD700;
      }

      .game-stats {
        display: flex;
        gap: 15px;
        align-items: center;
      }

      .moves {
        font-size: 18px;
        font-weight: bold;
        color: #FFD700;
      }

      .restart-btn {
        background: #FF6B6B;
        color: white;
        border: none;
        padding: 8px 15px;
        border-radius: 5px;
        cursor: pointer;
        font-size: 14px;
        transition: background 0.3s;
      }

      .restart-btn:hover {
        background: #FF5252;
      }

      .game-message {
        text-align: center;
        margin-bottom: 20px;
        padding: 10px;
        background: rgba(255, 255, 255, 0.1);
        border-radius: 5px;
        font-size: 16px;
      }

      .game-board {
        display: inline-block;
        background: #2c3e50;
        padding: 20px;
        border-radius: 10px;
        border: 3px solid #34495e;
        margin: 0 auto;
        box-shadow: 0 4px 20px rgba(0, 0, 0, 0.3);
      }

      .row {
        display: flex;
      }

      .cell {
        width: 40px;
        height: 40px;
        display: flex;
        align-items: center;
        justify-content: center;
        font-size: 24px;
        font-weight: bold;
        border: 1px solid #34495e;
        position: relative;
      }

      .cell.wall {
        background: #8B4513;
        color: #654321;
      }

      .cell.floor {
        background: #ECF0F1;
        color: #2C3E50;
      }

      .cell.goal {
        background: #F39C12;
        color: #E67E22;
      }

      .cell.box {
        background: #E74C3C;
        color: #C0392B;
      }

      .cell.box-on-goal {
        background: #27AE60;
        color: #229954;
      }

      .cell.player {
        background: #3498DB;
        color: #2980B9;
      }

      .cell.player-on-goal {
        background: #9B59B6;
        color: #8E44AD;
      }

      .game-instructions {
        margin-top: 30px;
        background: rgba(255, 255, 255, 0.1);
        padding: 20px;
        border-radius: 10px;
      }

      .game-instructions h3 {
        color: #FFD700;
        margin-top: 0;
      }

      .game-instructions ul {
        list-style: none;
        padding: 0;
      }

      .game-instructions li {
        margin: 8px 0;
        padding: 5px 0;
      }
    </style>
    """
  end

  # Helper functions for rendering
  defp cell_class("#", _pos, _goals), do: "wall"
  defp cell_class(" ", pos, goals) do
    if MapSet.member?(goals, pos), do: "goal", else: "floor"
  end
  defp cell_class(".", _pos, _goals), do: "goal"
  defp cell_class("$", pos, goals) do
    if MapSet.member?(goals, pos), do: "box-on-goal", else: "box"
  end
  defp cell_class("@", pos, goals) do
    if MapSet.member?(goals, pos), do: "player-on-goal", else: "player"
  end

  defp render_cell("#", _pos, _goals), do: "🧱"
  defp render_cell(" ", pos, goals) do
    if MapSet.member?(goals, pos), do: "🎯", else: "⬜"
  end
  defp render_cell(".", _pos, _goals), do: "🎯"
  defp render_cell("$", pos, goals) do
    if MapSet.member?(goals, pos), do: "✅", else: "📦"
  end
  defp render_cell("@", _pos, _goals), do: "🕹️"
end

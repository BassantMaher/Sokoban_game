defmodule SokobanTask1Web.GameLive do
  @moduledoc """
  LiveView for Sokoban game - Controller and View in MVC pattern.
  Handles user events and renders the game state.
  """
  use SokobanTask1Web, :live_view

  alias SokobanTask1.Game

  @impl true
  def mount(_params, _session, socket) do
    game = Game.new_level()

    socket =
      socket
      |> assign(:game, game)
      |> assign(:page_title, "Sokoban Game")

    {:ok, socket}
  end

  @impl true
  def handle_event("move", %{"direction" => direction}, socket) do
    direction_atom = String.to_existing_atom(direction)
    new_game = Game.move(socket.assigns.game, direction_atom)

    {:noreply, assign(socket, :game, new_game)}
  rescue
    ArgumentError ->
      # Invalid direction, ignore
      {:noreply, socket}
  end

  @impl true
  def handle_event("reset", _params, socket) do
    game = Game.new_level()
    {:noreply, assign(socket, :game, game)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="sokoban-game" phx-hook="KeyboardListener" id="game-container" tabindex="0">
      <h1 class="text-3xl font-bold text-center mb-6">Sokoban Game</h1>

      <div class="game-info text-center mb-4">
        <p class="text-gray-600">Use WASD or Arrow Keys to move</p>
        <p class="text-gray-600">Push all boxes onto green goals to win this challenging puzzle!</p>
      </div>

      <%= if @game.won do %>
        <div class="win-message text-center mb-4 p-4 bg-green-100 border border-green-400 text-green-700 rounded">
          <h2 class="text-2xl font-bold">🎉 You Won! 🎉</h2>
          <p>Congratulations! You solved the puzzle!</p>
        </div>
      <% end %>

      <div class="game-board-container">
        <div class="game-board">
          <%= for {row, y} <- Enum.with_index(@game.board) do %>
            <%= for {cell, x} <- Enum.with_index(String.graphemes(row)) do %>
              <div class={get_cell_classes(cell, x, y, @game)}>
                <%= cell_symbol(cell) %>
              </div>
            <% end %>
          <% end %>
        </div>
      </div>

      <div class="controls text-center">
        <.button phx-click="reset" class="bg-gray-500 hover:bg-gray-700 text-white font-bold py-2 px-4 rounded">
          Reset Level
        </.button>
      </div>

      <div class="instructions mt-6 text-sm text-gray-600">
        <h3 class="font-bold mb-2">How to Play:</h3>
        <ul class="list-disc list-inside space-y-1">
          <li>🚶 Player image = You</li>
          <li>📦 Box image = Boxes to push</li>
          <li>Green square = Goal (.)</li>
          <li>Gray square = Wall (#)</li>
          <li>Push all boxes onto goals to win!</li>
        </ul>
      </div>
    </div>
    """
  end

  # Helper functions for rendering

  defp get_cell_classes(cell, x, y, game) do
    base_classes = ["cell"]

    # Check if this position is a goal
    is_goal = MapSet.member?(game.goal_positions, {x, y})

    # Determine the visual class based on content and whether it's a goal
    cell_class = case {cell, is_goal} do
      {"#", _} -> "wall"
      {"@", true} -> "player-on-goal"
      {"@", false} -> "player"
      {"$", true} -> "box-on-goal"
      {"$", false} -> "box"
      {".", _} -> "goal"
      {" ", true} -> "goal"
      {" ", false} -> "empty"
      _ -> "empty"
    end

    base_classes ++ [cell_class]
  end

  defp cell_symbol("#"), do: ""
  defp cell_symbol("@"), do: ""
  defp cell_symbol("$"), do: ""
  defp cell_symbol("."), do: ""
  defp cell_symbol(" "), do: ""
  defp cell_symbol(_), do: ""
end

defmodule SokobanTask1Web.GameLive do
  @moduledoc """
  LiveView for Sokoban game - Controller and View in MVC pattern.
  Handles user events and renders the game state.
  """
  use SokobanTask1Web, :live_view

  alias SokobanTask1.Game

  @impl true
  def mount(_params, session, socket) do
    IO.puts("\n=== GAME MOUNT ===")
    IO.inspect(session, label: "Session")
    IO.inspect(socket.assigns, label: "Socket Assigns")
    
    # Get user from socket assigns (set by plug) or session
    current_user = get_current_user(socket, session)
    is_anonymous = get_anonymous_status(socket, session)
    
    IO.inspect(current_user, label: "Current User (final)")
    IO.inspect(is_anonymous, label: "Is Anonymous (final)")
    IO.puts("==================\n")

    # Load all levels
    levels = SokobanTask1.Levels.list_levels()

    # Start with first level or fallback
    game =
      case List.first(levels) do
        nil -> Game.new_level()
        level -> Game.new_from_level(level)
      end

    # Start timer - send tick message every second
    if connected?(socket) do
      :timer.send_interval(1000, self(), :tick)
    end

    socket =
      socket
      |> assign(:game, game)
      |> assign(:page_title, "Sokoban Game")
      |> assign(:current_user, current_user)
      |> assign(:anonymous, is_anonymous)
      |> assign(:start_time, System.system_time(:second))
      |> assign(:elapsed_time, 0)
      |> assign(:levels, levels)
      |> assign(:selected_level_id, game.level_id)
      |> assign(:best_score, load_best_score(current_user, game.level_id))

    {:ok, socket}
  rescue
    e ->
      IO.puts("\n❌ ERROR IN MOUNT:")
      IO.inspect(e)
      IO.inspect(__STACKTRACE__)
      {:ok, assign(socket, error: inspect(e))}
  end
  
  # Helper to get current user from socket or session
  defp get_current_user(socket, session) do
    cond do
      # Check socket assigns first (from plug)
      socket.assigns[:current_user] != nil ->
        socket.assigns[:current_user]
      
      # Check session for user_id
      is_integer(session["user_id"]) ->
        case SokobanTask1.Accounts.get_user(session["user_id"]) do
          nil -> nil
          user -> user
        end
      
      # No user found
      true ->
        nil
    end
  end
  
  # Helper to get anonymous status
  defp get_anonymous_status(socket, session) do
    socket.assigns[:anonymous] || session["anonymous"] || false
  end

  @impl true
  def handle_event("move", %{"direction" => direction}, socket) do
    direction_atom = String.to_existing_atom(direction)
    old_game = socket.assigns.game
    new_game = Game.move(old_game, direction_atom)

    socket = assign(socket, :game, new_game)

    # If game just won, save the score
    socket =
      if not old_game.won and new_game.won do
        save_score_on_win(socket)
      else
        socket
      end

    {:noreply, socket}
  rescue
    ArgumentError ->
      # Invalid direction, ignore
      {:noreply, socket}
  end

  @impl true
  def handle_event("reset", _params, socket) do
    # Reset current level
    level_id = socket.assigns.selected_level_id

    game =
      if level_id do
        level = SokobanTask1.Levels.get_level!(level_id)
        Game.new_from_level(level)
      else
        Game.new_level()
      end

    socket =
      socket
      |> assign(:game, game)
      |> assign(:start_time, System.system_time(:second))
      |> assign(:elapsed_time, 0)

    {:noreply, socket}
  end

  @impl true
  def handle_event("select_level", %{"level_id" => level_id_str}, socket) do
    IO.inspect(level_id_str, label: "Selecting level ID")

    level_id = String.to_integer(level_id_str)
    level = SokobanTask1.Levels.get_level!(level_id)
    game = Game.new_from_level(level)

    socket =
      socket
      |> assign(:game, game)
      |> assign(:selected_level_id, level_id)
      |> assign(:start_time, System.system_time(:second))
      |> assign(:elapsed_time, 0)
      |> assign(:best_score, load_best_score(socket.assigns.current_user, level_id))

    {:noreply, socket}
  rescue
    e ->
      IO.inspect(e, label: "Error selecting level")
      {:noreply, put_flash(socket, :error, "Failed to load level: #{inspect(e)}")}
  end

  @impl true
  def handle_info(:tick, socket) do
    # Update elapsed time if game is not won
    socket =
      if not socket.assigns.game.won do
        elapsed = System.system_time(:second) - socket.assigns.start_time
        assign(socket, :elapsed_time, elapsed)
      else
        socket
      end

    {:noreply, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="sokoban-game" phx-hook="KeyboardListener" id="game-container" tabindex="0">
      <div class="flex justify-between items-center mb-4">
        <h1 class="text-3xl font-bold">Sokoban Game</h1>
        <div class="flex items-center gap-4">
          <%= if @anonymous do %>
            <span class="text-sm text-gray-600">🎭 Playing as Anonymous</span>
          <% else %>
            <%= if @current_user do %>
              <span class="text-sm text-gray-600">
                👤 <%= @current_user.email %>
                <%= if @current_user.role == "admin" do %>
                  <span class="ml-2 px-2 py-1 bg-purple-100 text-purple-800 text-xs rounded">Admin</span>
                <% end %>
              </span>
            <% end %>
          <% end %>
          <a href="/logout" class="text-sm bg-red-500 hover:bg-red-600 text-white px-3 py-1 rounded">
            Logout
          </a>
        </div>
      </div>

      <!-- Level Selection -->
      <div class="mb-4 p-4 bg-gradient-to-r from-blue-50 to-indigo-50 rounded-lg border border-blue-200">
        <div class="flex items-center gap-4 mb-2">
          <label for="level-select" class="text-sm font-medium text-gray-700">Select Level:</label>
          <form phx-change="select_level" class="flex-1">
            <select
              id="level-select"
              name="level_id"
              class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
            >
              <%= for level <- @levels do %>
                <option value={level.id} selected={level.id == @selected_level_id}>
                  <%= level.order %>. <%= level.name %> - <%= String.capitalize(to_string(level.difficulty)) %>
                </option>
              <% end %>
            </select>
          </form>
          <button
            phx-click="reset"
            class="px-4 py-2 bg-blue-500 text-white rounded hover:bg-blue-600 transition"
          >
            Reset
          </button>
        </div>
        <div class="text-center">
          <span class="text-lg font-semibold text-gray-800">
            <%= @game.level_name %>
          </span>
        </div>
      </div>

      <div class="game-info text-center mb-4">
        <p class="text-gray-600">Use WASD or Arrow Keys to move</p>
        <p class="text-gray-600">Push all boxes onto green goals to win this challenging puzzle!</p>
      </div>

      <div class="stats-bar flex justify-center gap-8 mb-4 text-lg font-semibold">
        <div class="stat">
          <span class="text-gray-600">⏱️ Time:</span>
          <span class="text-blue-600"><%= format_time(@elapsed_time) %></span>
        </div>
        <div class="stat">
          <span class="text-gray-600">🚶 Moves:</span>
          <span class="text-green-600"><%= @game.moves %></span>
        </div>
        <%= if @best_score do %>
          <div class="stat">
            <span class="text-gray-600">⭐ Best:</span>
            <span class="text-purple-600"><%= format_time(@best_score.time_seconds) %> / <%= @best_score.moves %>m</span>
          </div>
        <% end %>
      </div>

      <%= if @game.won do %>
        <div class="win-message text-center mb-4 p-4 bg-green-100 border border-green-400 text-green-700 rounded">
          <h2 class="text-2xl font-bold">🎉 You Won! 🎉</h2>
          <p>Time: <%= format_time(@elapsed_time) %> | Moves: <%= @game.moves %></p>
          <%= if @best_score && @best_score.time_seconds == @elapsed_time && @best_score.moves == @game.moves do %>
            <p class="text-sm mt-2">🏆 This is your best score!</p>
          <% end %>
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

  # Score management helpers

  defp load_best_score(nil, _level_id), do: nil

  defp load_best_score(user, level_id) do
    SokobanTask1.Scores.get_user_best_score(user.id, level_id)
  end

  defp save_score_on_win(socket) do
    game = socket.assigns.game
    user = socket.assigns.current_user
    is_anonymous = socket.assigns[:anonymous] || false
    elapsed_time = socket.assigns.elapsed_time

    # Debug logging
    IO.puts("\n=== SAVE SCORE DEBUG ===")
    IO.inspect(user, label: "Current User")
    IO.inspect(is_anonymous, label: "Is Anonymous")
    IO.inspect(game.level_id, label: "Level ID")
    IO.inspect(elapsed_time, label: "Time")
    IO.inspect(game.moves, label: "Moves")
    IO.puts("========================\n")

    # Save score for logged-in users (always save, not just best)
    if !is_anonymous && user != nil && game.level_id != nil do
      case SokobanTask1.Scores.save_score(user.id, game.level_id, elapsed_time, game.moves) do
        {:ok, score, :new_best} ->
          IO.puts("✅ Score saved as NEW BEST!")
          socket
          |> assign(:best_score, score)
          |> put_flash(:info, "🎉 Congratulations! You won! New best score! Time: #{format_time(elapsed_time)}, Moves: #{game.moves}")

        {:ok, _score, :not_best} ->
          IO.puts("✅ Score saved but not best")
          socket
          |> assign(:best_score, load_best_score(user, game.level_id))
          |> put_flash(:info, "🎉 Congratulations! Level completed! Time: #{format_time(elapsed_time)}, Moves: #{game.moves}. (Not your best score)")

        {:error, changeset} ->
          IO.puts("❌ Failed to save score:")
          IO.inspect(changeset)
          socket
          |> put_flash(:info, "🎉 Congratulations! You won! Time: #{format_time(elapsed_time)}, Moves: #{game.moves}")
          |> put_flash(:error, "Failed to save score. Please check the logs.")
      end
    else
      # Anonymous user or no level_id - just show completion message
      reason = cond do
        is_anonymous -> "Playing as anonymous"
        user == nil -> "No user logged in"
        game.level_id == nil -> "No level ID"
        true -> "Unknown reason"
      end
      IO.puts("⚠️ Score NOT saved: #{reason}")
      put_flash(socket, :info, "🎉 Congratulations! You won! Time: #{format_time(elapsed_time)}, Moves: #{game.moves} (Score not saved - #{reason})")
    end
  end

  defp format_time(seconds) do
    minutes = div(seconds, 60)
    secs = rem(seconds, 60)
    "#{minutes}:#{String.pad_leading(Integer.to_string(secs), 2, "0")}"
  end
end

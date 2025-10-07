defmodule SokobanTask1Web.GameLive do
  @moduledoc """
  LiveView for Sokoban game with database integration and timer functionality.
  """
  use SokobanTask1Web, :live_view

  alias SokobanTask1.Game
  alias SokobanTask1.Game.Level
  alias SokobanTask1.GameContext
  alias SokobanTask1.Accounts

  @impl true
  def mount(_params, session, socket) do
    # Get user from Guardian token in session
    user = case session["guardian_default_token"] do
      nil -> nil
      token ->
        case SokobanTask1.Guardian.get_user_from_token(token) do
          {:ok, user} -> user
          {:error, _reason} -> nil
        end
    end

    # Redirect to login if no user found - use push_navigate for immediate redirect
    if is_nil(user) do
      {:ok, push_navigate(socket, to: ~p"/login")}
    else
      # Start with level 1 for authenticated users
      levels = GameContext.list_levels()

      # Debug logging
      IO.puts("Found #{length(levels)} levels for user #{user.email}")

      current_level = case levels do
        [] ->
          IO.puts("No levels found, creating default level")
          create_default_level()
        _ ->
          Enum.at(levels, 0)
      end

      # Check for existing active session or create new one
      game_session = GameContext.get_active_game_session(user.id, current_level.id) ||
                     create_new_session(user.id, current_level.id)

      # Initialize game state from session or level data
      game = if game_session && game_session.current_board do
        # Load from existing session
        case Jason.decode(game_session.current_board) do
          {:ok, board_data} ->
            Game.new_level_from_data(board_data)
          {:error, _} ->
            # Fallback to level data if session board is corrupted
            case Level.parse_board_data(current_level.board_data) do
              {:ok, board} ->
                Game.new_level_from_data(board)
              {:error, _} ->
                Game.new_level()
            end
        end
      else
        # Create new game from level data
        case Level.parse_board_data(current_level.board_data) do
          {:ok, board} ->
            Game.new_level_from_data(board)
          {:error, _} ->
            Game.new_level()
        end
      end

      socket =
        socket
        |> assign(:current_user, user)
        |> assign(:user, user)
        |> assign(:current_level, current_level)
        |> assign(:levels, levels)
        |> assign(:game_session, game_session)
        |> assign(:game, game)
        |> assign(:timer_start, DateTime.utc_now() |> DateTime.truncate(:second))
        |> assign(:elapsed_time, 0)
        |> assign(:moves_count, if(game_session, do: game_session.moves_count, else: 0))
        |> assign(:page_title, "Sokoban Game - #{current_level.name}")

      # Start timer for tracking time only if connected
      if connected?(socket) do
        :timer.send_interval(1000, self(), :update_timer)
      end

      {:ok, socket}
    end
  end

  @impl true
  def handle_info(:update_timer, socket) do
    # Don't update timer if game is completed or won
    if socket.assigns[:game_completed] || socket.assigns.game.won do
      {:noreply, socket}
    else
      elapsed = DateTime.diff(DateTime.utc_now() |> DateTime.truncate(:second), socket.assigns.timer_start, :second)
      {:noreply, assign(socket, :elapsed_time, elapsed)}
    end
  end

  @impl true
  def handle_event("move", %{"direction" => direction}, socket) do
    direction_atom = String.to_existing_atom(direction)
    old_game = socket.assigns.game
    new_game = Game.move(socket.assigns.game, direction_atom)

    # Debug: Check if game state actually changed
    game_changed = old_game != new_game
    player_moved = old_game.player_pos != new_game.player_pos

    IO.puts("\n🎮 MOVE EVENT: #{direction}")
    IO.puts("   Old player pos: #{inspect(old_game.player_pos)}")
    IO.puts("   New player pos: #{inspect(new_game.player_pos)}")
    IO.puts("   Game changed: #{game_changed}")
    IO.puts("   Player moved: #{player_moved}")
    IO.puts("   Board equal: #{old_game.board == new_game.board}")

    # Update move count and save to database if user is logged in
    socket =
      if new_game != socket.assigns.game do
        new_moves_count = socket.assigns.moves_count + 1

        socket = assign(socket, :moves_count, new_moves_count)

        # Update game session in database if user is logged in
        socket = if socket.assigns.user && socket.assigns.game_session do
          move_data = %{
            direction: direction,
            timestamp: DateTime.utc_now() |> DateTime.truncate(:second),
            board_state: new_game.board
          }

          # Encode board as JSON string for database storage
          encoded_board = case Jason.encode(new_game.board) do
            {:ok, json} -> json
            {:error, _} -> Jason.encode!(socket.assigns.game.board)  # fallback to current board
          end

          # Update database and handle response for LiveView updates
          case GameContext.make_move(
            socket.assigns.game_session.id,
            encoded_board,
            move_data
          ) do
            {:ok, updated_session} ->
              # Update socket with new session data for real-time updates
              assign(socket, :game_session, updated_session)
            {:error, _reason} ->
              # Log error but continue with game state update
              IO.warn("Failed to save move to database")
              socket
          end
        else
          socket
        end

        socket
      else
        socket
      end

    # Always update the game state to ensure UI reflects changes
    socket = assign(socket, :game, new_game)

    IO.puts("   ✅ Game state assigned to socket")
    IO.puts("   Socket game player_pos after assign: #{inspect(socket.assigns.game.player_pos)}")
    IO.puts("   Moves count: #{socket.assigns.moves_count}\n")

    # Check if level is completed
    socket =
      if new_game.won && !old_game.won do
        IO.puts("🏆 LEVEL COMPLETED!")
        handle_level_completion(socket, new_game)
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
    if socket.assigns.user && socket.assigns.current_level do
      # Reset the current level for authenticated user
      game = case Level.parse_board_data(socket.assigns.current_level.board_data) do
        {:ok, board} ->
          Game.new_level_from_data(board)
        {:error, _} ->
          Game.new_level()
      end

      # Abandon current session and start new one
      if socket.assigns.game_session do
        GameContext.abandon_game_session(socket.assigns.game_session.id)
      end

      new_session = create_new_session(socket.assigns.user.id, socket.assigns.current_level.id)

      socket =
        socket
        |> assign(:game, game)
        |> assign(:game_session, new_session)
        |> assign(:moves_count, 0)
        |> assign(:timer_start, DateTime.utc_now() |> DateTime.truncate(:second))
        |> assign(:elapsed_time, 0)

      {:noreply, socket}
    else
      # Anonymous user reset
      game = Game.new_level()

      socket =
        socket
        |> assign(:game, game)
        |> assign(:moves_count, 0)
        |> assign(:timer_start, DateTime.utc_now() |> DateTime.truncate(:second))
        |> assign(:elapsed_time, 0)

      {:noreply, socket}
    end
  end

  @impl true
  def handle_event("next_level", _params, socket) do
    if socket.assigns.user && socket.assigns.levels do
      current_index = Enum.find_index(socket.assigns.levels, &(&1.id == socket.assigns.current_level.id))
      next_level = Enum.at(socket.assigns.levels, current_index + 1)

      if next_level do
        load_level(socket, next_level)
      else
        # No more levels
        {:noreply, put_flash(socket, :info, "Congratulations! You've completed all levels!")}
      end
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_event("load_level", params, socket) do
    # Extract level_id from params (can be %{"level_id" => ...} or %{"_target" => [...], "level_id" => ...})
    level_id = params["level_id"] || params["value"]

    IO.puts("\n🔍 Loading level: #{inspect(level_id)}")
    IO.puts("   Params: #{inspect(params)}")

    if socket.assigns.user && level_id do
      level = Enum.find(socket.assigns.levels, &(&1.id == level_id))

      if level do
        IO.puts("   ✅ Found level: #{level.name}")
        load_level(socket, level)
      else
        IO.puts("   ❌ Level not found: #{level_id}")
        {:noreply, put_flash(socket, :error, "Level not found")}
      end
    else
      IO.puts("   ❌ No user or level_id")
      {:noreply, socket}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <%= if assigns[:game] do %>
      <div class="sokoban-game" phx-hook="KeyboardListener" id="game-container" tabindex="0">
        <div class="game-header mb-6">
          <h1 class="text-3xl font-bold text-center mb-4">Sokoban Game</h1>

          <%= if @current_level do %>
            <div class="level-info text-center mb-4">
              <h2 class="text-xl font-semibold text-purple-700"><%= @current_level.name %></h2>
              <p class="text-gray-600"><%= @current_level.description %></p>
              <div class="flex justify-center gap-6 mt-2 text-sm" id="game-stats">
                <span>Difficulty: <strong><%= String.capitalize(to_string(@current_level.difficulty)) %></strong></span>
                <span id="moves-counter">Moves: <strong><%= @moves_count %></strong></span>
                <span id="timer-display">Time: <strong><%= format_time(@elapsed_time) %></strong></span>
              </div>
            </div>
          <% else %>
            <div class="text-center mb-4">
              <p class="text-gray-600">Use WASD or Arrow Keys to move</p>
              <p class="text-gray-600">Push all boxes onto green goals to win this challenging puzzle!</p>
              <div class="mt-2 text-sm" id="anonymous-game-stats">
                <span id="anonymous-moves-counter">Moves: <strong><%= @moves_count %></strong></span>
                <span class="ml-4" id="anonymous-timer-display">Time: <strong><%= format_time(@elapsed_time) %></strong></span>
              </div>
            </div>
          <% end %>
        </div>

      <%= if @game.won do %>
        <div class="win-message text-center mb-4 p-4 bg-green-100 border border-green-400 text-green-700 rounded" id="win-notification">
          <h2 class="text-2xl font-bold">🎉 You Won! 🎉</h2>
          <p>Congratulations! You solved the puzzle!</p>
          <div class="mt-2">
            <p>Completed in <strong><%= @moves_count %></strong> moves and <strong><%= format_time(@elapsed_time) %></strong></p>
          </div>

          <%= if @user && has_next_level?(@levels, @current_level) do %>
            <div class="mt-4">
              <.button phx-click="next_level" class="bg-green-500 hover:bg-green-700 text-white font-bold py-2 px-4 rounded mr-2">
                Next Level
              </.button>
            </div>
          <% end %>
        </div>
      <% end %>

      <div class="game-board-container">
        <div class="game-board" id="sokoban-board" style={"grid-template-columns: repeat(#{get_board_width(@game.board)}, 40px); grid-template-rows: repeat(#{length(@game.board)}, 40px);"} tabindex="0">
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
        <.button phx-click="reset" class="bg-gray-500 hover:bg-gray-700 text-white font-bold py-2 px-4 rounded mr-2">
          Reset Level
        </.button>

        <%= if @user && @levels && length(@levels) > 1 do %>
          <select class="ml-2 px-3 py-2 border rounded" phx-change="load_level" name="level_id">
            <%= for level <- @levels do %>
              <option value={level.id} selected={level.id == @current_level.id}>
                <%= level.name %> (<%= String.capitalize(to_string(level.difficulty)) %>)
              </option>
            <% end %>
          </select>
        <% end %>
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

        <%= if @user do %>
          <div class="mt-4 p-3 bg-blue-50 rounded">
            <h4 class="font-bold text-blue-800">Progress Tracking</h4>
            <p class="text-blue-700">Your moves and completion times are being tracked and saved!</p>
          </div>
        <% else %>
          <div class="mt-4 p-3 bg-yellow-50 rounded">
            <h4 class="font-bold text-yellow-800">Want to Track Progress?</h4>
            <p class="text-yellow-700">
              <a href="/login" class="underline">Log in</a> or
              <a href="/register" class="underline">create an account</a>
              to save your progress and compete on leaderboards!
            </p>
          </div>
        <% end %>
      </div>
    </div>
    <% else %>
      <div class="loading-container text-center py-8">
        <p class="text-gray-600">Loading game...</p>
      </div>
    <% end %>
    """
  end

  # Helper functions for rendering and game logic

  defp create_new_session(user_id, level_id) do
    IO.puts("Creating new game session for user #{user_id}, level #{level_id}")
    case GameContext.start_game_session(user_id, level_id) do
      {:ok, session} ->
        IO.puts("✅ Game session created successfully: #{session.id}")
        session
      {:error, reason} ->
        IO.puts("❌ Failed to create game session: #{inspect(reason)}")
        nil
    end
  end

  defp create_default_level do
    # Create a basic level if none exist
    %{
      id: "default",
      name: "Default Level",
      description: "A simple puzzle to get started",
      difficulty: :easy,
      order: 1,
      board: [
        "#######",
        "#.....#",
        "#..#..#",
        "#.$@$.#",
        "#..#..#",
        "#.....#",
        "#######"
      ]
    }
  end

  defp handle_level_completion(socket, completed_game) do
    socket = assign(socket, :game, completed_game)

    # Always stop the timer when game is completed
    socket = assign(socket, :game_completed, true)

    # Save completion if user is logged in
    if socket.assigns.user && socket.assigns.game_session do
      time_taken = socket.assigns.elapsed_time

      # Complete the game session
      encoded_final_board = case Jason.encode(completed_game.board) do
        {:ok, json} -> json
        {:error, _} -> "[]"  # fallback to empty board
      end

      case GameContext.complete_game_session(
        socket.assigns.game_session.id,
        encoded_final_board
      ) do
        {:ok, _completed_session} ->
          # Update user stats
          Accounts.update_user_stats(socket.assigns.user.id, true)

          # Show completion message with stats
          socket = put_flash(socket, :info, "Level completed in #{socket.assigns.moves_count} moves and #{format_time(time_taken)}!")

          socket

        {:error, _} ->
          socket = put_flash(socket, :error, "Error saving completion data")
          socket
      end
    else
      # For anonymous users, just show completion message
      time_taken = socket.assigns.elapsed_time
      socket = put_flash(socket, :info, "Level completed in #{socket.assigns.moves_count} moves and #{format_time(time_taken)}!")
      socket
    end
  end

  defp load_level(socket, level) do
    user = socket.assigns.user

    # Abandon current session if exists
    if socket.assigns.game_session do
      GameContext.abandon_game_session(socket.assigns.game_session.id)
    end

    # Create new session for the level
    new_session = create_new_session(user.id, level.id)

    # Initialize game with level data
    game = case Level.parse_board_data(level.board_data) do
      {:ok, board} ->
        Game.new_level_from_data(board)
      {:error, _} ->
        Game.new_level()
    end

    socket =
      socket
      |> assign(:current_level, level)
      |> assign(:game_session, new_session)
      |> assign(:game, game)
      |> assign(:moves_count, 0)
      |> assign(:timer_start, DateTime.utc_now() |> DateTime.truncate(:second))
      |> assign(:elapsed_time, 0)
      |> assign(:page_title, "Sokoban Game - #{level.name}")

    {:noreply, socket}
  end

  defp has_next_level?(levels, current_level) do
    current_index = Enum.find_index(levels, &(&1.id == current_level.id))
    current_index && current_index < length(levels) - 1
  end

  defp format_time(seconds) do
    minutes = div(seconds, 60)
    remaining_seconds = rem(seconds, 60)
    :io_lib.format("~2..0B:~2..0B", [minutes, remaining_seconds]) |> to_string()
  end

  defp get_board_width(board) when is_list(board) and length(board) > 0 do
    board |> List.first() |> String.length()
  end

  defp get_board_width(_), do: 12  # Default width

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

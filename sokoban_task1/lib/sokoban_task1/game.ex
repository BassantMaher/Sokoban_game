defmodule SokobanTask1.Game do
  @moduledoc """
  Game logic for Sokoban - Model in MVC pattern.
  Handles game state as immutable struct and game rules.
  """

  defstruct [:board, :player_pos, :width, :height, :won, :goal_positions]

  @type t :: %__MODULE__{
          board: [String.t()],
          player_pos: {integer(), integer()},
          width: integer(),
          height: integer(),
          won: boolean(),
          goal_positions: MapSet.t()
        }

  @doc "Creates a new game with the default level"
  @spec new_level() :: t()
  def new_level do
    # Larger and more challenging level: player (@), box ($), goal (.), wall (#), empty ( )
    # This level requires strategic thinking to push boxes in the right order
    board = [
      "############",
      "#@         #",
      "# $$ ## $$ #",
      "#  .  .  . #",
      "## ### ### #",
      "#  $  $  $ #",
      "#  .  .  . #",
      "# $$ ## $$ #",
      "#    ..    #",
      "############"
    ]

    {player_x, player_y} = find_player(board)
    goal_positions = find_goals(board)

    %__MODULE__{
      board: board,
      player_pos: {player_x, player_y},
      width: String.length(Enum.at(board, 0)),
      height: length(board),
      won: false,
      goal_positions: goal_positions
    }
  end

  @doc "Attempts to move the player in the given direction"
  @spec move(t(), :up | :down | :left | :right) :: t()
  def move(%__MODULE__{won: true} = game, _direction), do: game

  def move(%__MODULE__{} = game, direction) do
    {dx, dy} = direction_delta(direction)
    {px, py} = game.player_pos
    new_x = px + dx
    new_y = py + dy

    cond do
      # Out of bounds or hitting wall
      out_of_bounds?(game, new_x, new_y) or get_cell(game, new_x, new_y) == "#" ->
        game

      # Moving to empty space or goal
      get_cell(game, new_x, new_y) in [" ", "."] ->
        game
        |> move_player_to(new_x, new_y)
        |> check_win()

      # Trying to push a box
      get_cell(game, new_x, new_y) == "$" ->
        push_box(game, px, py, new_x, new_y, dx, dy)

      # Invalid move
      true ->
        game
    end
  end

  @doc "Checks if the game is won (all boxes on goals)"
  @spec check_win?(t()) :: boolean()
  def check_win?(%__MODULE__{board: board, goal_positions: goal_positions}) do
    # Check if all goal positions have boxes on them
    goal_positions
    |> Enum.all?(fn {x, y} ->
      row = Enum.at(board, y, "")
      String.at(row, x) == "$"
    end)
  end

  # Private functions

  defp find_player(board) do
    board
    |> Enum.with_index()
    |> Enum.find_value(fn {row, y} ->
      case String.graphemes(row) |> Enum.find_index(&(&1 == "@")) do
        nil -> nil
        x -> {x, y}
      end
    end) || {0, 0}
  end

  defp find_goals(board) do
    board
    |> Enum.with_index()
    |> Enum.reduce(MapSet.new(), fn {row, y}, acc ->
      row
      |> String.graphemes()
      |> Enum.with_index()
      |> Enum.reduce(acc, fn {cell, x}, acc2 ->
        if cell == ".", do: MapSet.put(acc2, {x, y}), else: acc2
      end)
    end)
  end

  defp direction_delta(:up), do: {0, -1}
  defp direction_delta(:down), do: {0, 1}
  defp direction_delta(:left), do: {-1, 0}
  defp direction_delta(:right), do: {1, 0}

  defp out_of_bounds?(%__MODULE__{width: w, height: h}, x, y) do
    x < 0 or y < 0 or x >= w or y >= h
  end

  defp get_cell(%__MODULE__{board: board}, x, y) do
    row = Enum.at(board, y, "")
    String.at(row, x) || "#"
  end

  defp move_player_to(%__MODULE__{goal_positions: goal_positions} = game, new_x, new_y) do
    {old_x, old_y} = game.player_pos

    # Remove player from old position, restore goal if there was one
    new_old_cell = if MapSet.member?(goal_positions, {old_x, old_y}), do: ".", else: " "
    board_without_player = set_cell(game.board, old_x, old_y, new_old_cell)

    # Place player at new position
    new_board = set_cell(board_without_player, new_x, new_y, "@")

    %{game | board: new_board, player_pos: {new_x, new_y}}
  end

  defp push_box(%__MODULE__{} = game, _px, _py, box_x, box_y, dx, dy) do
    # Check if we can push the box
    behind_box_x = box_x + dx
    behind_box_y = box_y + dy

    cond do
      # Can't push out of bounds
      out_of_bounds?(game, behind_box_x, behind_box_y) ->
        game

      # Can't push into wall or another box
      get_cell(game, behind_box_x, behind_box_y) in ["#", "$"] ->
        game

      # Can push into empty space or goal
      get_cell(game, behind_box_x, behind_box_y) in [" ", "."] ->
        game
        |> move_box(box_x, box_y, behind_box_x, behind_box_y)
        |> move_player_to(box_x, box_y)
        |> check_win()

      true ->
        game
    end
  end

  defp move_box(%__MODULE__{goal_positions: goal_positions} = game, from_x, from_y, to_x, to_y) do
    # Remove box from old position, restore goal if there was one
    new_from_cell = if MapSet.member?(goal_positions, {from_x, from_y}), do: ".", else: " "
    board_without_box = set_cell(game.board, from_x, from_y, new_from_cell)

    # Place box at new position
    new_board = set_cell(board_without_box, to_x, to_y, "$")
    %{game | board: new_board}
  end

  defp set_cell(board, x, y, new_char) do
    List.update_at(board, y, fn row ->
      row
      |> String.graphemes()
      |> List.replace_at(x, new_char)
      |> Enum.join("")
    end)
  end

  defp check_win(%__MODULE__{} = game) do
    %{game | won: check_win?(game)}
  end
end

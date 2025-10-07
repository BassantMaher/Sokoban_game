alias SokobanTask1.{Repo, GameContext}
alias SokobanTask1.Game.Level

# Clear existing levels
Repo.delete_all(Level)

# Helper function to prepare level data
prepare_level_data = fn level_data ->
  board = level_data.board
  board_data = Jason.encode!(board)
  width = String.length(Enum.at(board, 0))
  height = length(board)

  level_data
  |> Map.put(:board_data, board_data)
  |> Map.put(:width, width)
  |> Map.put(:height, height)
  |> Map.put(:is_published, true)  # Make sure levels are published
  |> Map.put(:is_official, true)   # Mark as official levels
  |> Map.delete(:board)
end

# Seed levels with different difficulties
levels = [
  # Easy levels
  %{
    name: "First Steps",
    difficulty: :easy,
    description: "Learn the basics of Sokoban. Push the box to the goal.",
    board: [
      "######",
      "#@$. #",
      "######"
    ],
    minimum_moves: 1
  },
  %{
    name: "Two Boxes",
    difficulty: :easy,
    description: "Push both boxes to their goals.",
    board: [
      "#######",
      "#@    #",
      "# $$ .#",
      "#   ..#",
      "#######"
    ],
    minimum_moves: 4
  },
  %{
    name: "Corner Challenge",
    difficulty: :easy,
    description: "Be careful not to push boxes into corners!",
    board: [
      "########",
      "#@     #",
      "# $ $  #",
      "#  ..  #",
      "########"
    ],
    minimum_moves: 6
  },

  # Medium levels
  %{
    name: "Strategic Thinking",
    difficulty: :medium,
    description: "Think ahead! Order matters here.",
    board: [
      "#########",
      "#@      #",
      "# $ $ $ #",
      "#  ...  #",
      "# ##### #",
      "#       #",
      "#########"
    ],
    minimum_moves: 10
  },
  %{
    name: "The Maze",
    difficulty: :medium,
    description: "Navigate through the maze to place all boxes.",
    board: [
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
    ],
    minimum_moves: 25
  },
  %{
    name: "Warehouse Worker",
    difficulty: :medium,
    description: "A real warehouse challenge!",
    board: [
      "##############",
      "#@           #",
      "# $ $ $ $ $  #",
      "#            #",
      "# ########## #",
      "# #........# #",
      "# #........# #",
      "# ########## #",
      "#            #",
      "##############"
    ],
    minimum_moves: 20
  },

  # Hard levels
  %{
    name: "Master Puzzle",
    difficulty: :hard,
    description: "Only for experienced players. Think carefully!",
    board: [
      "################",
      "#@.            #",
      "# $ $ $ $ $ $  #",
      "#              #",
      "# ############ #",
      "# #..........# #",
      "# #..........# #",
      "# #..........# #",
      "# ############ #",
      "#      $ $     #",
      "#    ......    #",
      "################"
    ],
    minimum_moves: 35
  },
  %{
    name: "The Ultimate Test",
    difficulty: :hard,
    description: "The hardest puzzle. Can you solve it?",
    board: [
      "############",
      "#@         #",
      "# $ $ $ $  #",
      "#          #",
      "# ........ #",
      "#          #",
      "############"
    ],
    minimum_moves: 50
  }
]

IO.puts("Seeding levels...")

levels
|> Enum.map(prepare_level_data)
|> Enum.each(fn level_attrs ->
  case GameContext.create_level(level_attrs) do
    {:ok, level} ->
      IO.puts("Created level: #{level.name} (#{level.difficulty})")

    {:error, changeset} ->
      IO.puts("Failed to create level: #{level_attrs.name}")
      IO.inspect(changeset.errors)
  end
end)

IO.puts("Seeding complete!")
IO.puts("Created #{Repo.aggregate(Level, :count, :id)} levels.")

# Script for populating the database with initial levels
# You can run it with: mix run priv/repo/seeds.exs

alias SokobanTask1.Repo
alias SokobanTask1.Levels.Level

# Clear existing levels (optional - remove if you want to keep existing data)
Repo.delete_all(Level)

# Level 1 - Easy - Classic Small Room
{:ok, _level1} = Repo.insert(%Level{
  name: "Classic Challenge",
  difficulty: "medium",
  order: 1,
  description: "A challenging classic Sokoban puzzle. Push all boxes to green goals!",
  board_data: [
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
})

# Level 2 - Easy - Simple Start
{:ok, _level2} = Repo.insert(%Level{
  name: "First Steps",
  difficulty: "easy",
  order: 2,
  description: "Perfect for beginners. Learn the basics!",
  board_data: [
    "#######",
    "#     #",
    "# $.$ #",
    "# .@. #",
    "# $.$ #",
    "#     #",
    "#######"
  ]
})

# Level 3 - Easy - Corner Push
{:ok, _level3} = Repo.insert(%Level{
  name: "Corner Challenge",
  difficulty: "easy",
  order: 3,
  description: "Watch out for corners! Plan your moves carefully.",
  board_data: [
    "########",
    "#   .  #",
    "#  $$  #",
    "# .@.  #",
    "#  $$  #",
    "#   .  #",
    "########"
  ]
})

# Level 4 - Medium - Warehouse
{:ok, _level4} = Repo.insert(%Level{
  name: "The Warehouse",
  difficulty: "medium",
  order: 4,
  description: "A bigger warehouse with more boxes to organize.",
  board_data: [
    "##########",
    "#        #",
    "# $$ $ $ #",
    "# $   .  #",
    "#.  @  . #",
    "#  .   $ #",
    "# $ $ $$ #",
    "#        #",
    "##########"
  ]
})

# Level 5 - Medium - Maze
{:ok, _level5} = Repo.insert(%Level{
  name: "The Maze",
  difficulty: "medium",
  order: 5,
  description: "Navigate through the maze while pushing boxes.",
  board_data: [
    "###########",
    "#  #   #  #",
    "# $. #.$ ##",
    "# #  @  # #",
    "# $ #.# $ #",
    "#  . # .  #",
    "## $   $ ##",
    "#  # # #  #",
    "###########"
  ]
})

# Level 6 - Hard - Precision Required
{:ok, _level6} = Repo.insert(%Level{
  name: "Precision Master",
  difficulty: "hard",
  order: 6,
  description: "Every move counts! One wrong push and you're stuck.",
  board_data: [
    "##########",
    "#    .   #",
    "# #$ $#  #",
    "# . .@ . #",
    "#  #$ $# #",
    "#   .    #",
    "##########"
  ]
})

# Level 7 - Hard - The Cross
{:ok, _level7} = Repo.insert(%Level{
  name: "The Cross",
  difficulty: "hard",
  order: 7,
  description: "A cross-shaped puzzle that requires strategic thinking.",
  board_data: [
    "    ###    ",
    "    #.#    ",
    "  ###$###  ",
    "  #.$ $.#  ",
    "###$ @ $###",
    "#.$ $ $ $.#",
    "###$ $ $###",
    "  #.$ $.#  ",
    "  ###$###  ",
    "    #.#    ",
    "    ###    "
  ]
})

# Level 8 - Expert - The Spiral
{:ok, _level8} = Repo.insert(%Level{
  name: "The Spiral",
  difficulty: "expert",
  order: 8,
  description: "Master level! Navigate the spiral pattern.",
  board_data: [
    "############",
    "#   .      #",
    "# ## #### ##",
    "# #   #   .#",
    "# # $$# ## #",
    "# #  $@  # #",
    "# # ## #$# #",
    "# #.  $  # #",
    "# ######## #",
    "#.         #",
    "############"
  ]
})

# Level 9 - Expert - The Tower
{:ok, _level9} = Repo.insert(%Level{
  name: "The Tower",
  difficulty: "expert",
  order: 9,
  description: "Climb the tower by solving each floor!",
  board_data: [
    "    ####    ",
    "    #. #    ",
    "  ###$$###  ",
    "  #  $.  #  ",
    "  # $@$  #  ",
    "###  $.  ###",
    "#  $$.$$.  #",
    "#  .    .  #",
    "############"
  ]
})

# Level 10 - Expert - The Master's Final Test
{:ok, _level10} = Repo.insert(%Level{
  name: "Master's Final Test",
  difficulty: "expert",
  order: 10,
  description: "Only true masters can complete this ultimate challenge!",
  board_data: [
    "##############",
    "#     .      #",
    "# ##$### ##  #",
    "# # . .# #$  #",
    "# #$ $ $ #   #",
    "# # . .# # $ #",
    "# ##$### ##  #",
    "#   @ .      #",
    "# ##$### ##  #",
    "# # . .# #$  #",
    "# #$ $ $ #   #",
    "# # . .# #   #",
    "# ##$### ##  #",
    "#     .      #",
    "##############"
  ]
})

IO.puts("✅ Seeded #{Repo.aggregate(Level, :count, :id)} levels successfully!")

# Script to fix any board_data that might have atoms instead of strings
# Run with: mix run priv/repo/fix_board_data.exs

alias SokobanTask1.Repo
alias SokobanTask1.Levels.Level
import Ecto.Query

# Get all levels
levels = Repo.all(Level)

IO.puts("Found #{length(levels)} levels to check...")

Enum.each(levels, fn level ->
  # Check if any board_data rows are not strings
  needs_fix = Enum.any?(level.board_data, fn row ->
    not is_binary(row)
  end)

  if needs_fix do
    IO.puts("Fixing level ##{level.order}: #{level.name}")

    # Convert all rows to strings
    fixed_board_data = Enum.map(level.board_data, fn row ->
      cond do
        is_binary(row) -> row
        is_atom(row) -> Atom.to_string(row)
        true -> to_string(row)
      end
    end)

    # Update the level
    level
    |> Ecto.Changeset.change(board_data: fixed_board_data)
    |> Repo.update()

    IO.puts("  ✅ Fixed!")
  else
    IO.puts("Level ##{level.order}: #{level.name} - OK")
  end
end)

IO.puts("\n✅ All levels checked and fixed if needed!")

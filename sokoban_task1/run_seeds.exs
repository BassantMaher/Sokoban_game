# Run seeds script
System.cmd("mix", ["ecto.setup"], into: IO.stream(:stdio, :line))

# Now update levels to be published
Mix.install([])

defmodule DatabaseSeeder do
  def run do
    System.cmd("psql", ["-d", "sokoban_task1_dev", "-c",
      "UPDATE levels SET is_published = true, is_official = true;"])
  end
end

DatabaseSeeder.run()
IO.puts("Seeds completed - levels marked as published")

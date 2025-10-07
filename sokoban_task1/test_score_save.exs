# Quick Test Script to Verify Score Saving

# Run this to test if score saving works:
# mix run test_score_save.exs

alias SokobanTask1.{Repo, Accounts, Levels, Scores}

IO.puts("\n=== Testing Score Save Functionality ===\n")

# 1. Check if we have users
IO.puts("1. Checking for users...")
users = Repo.all(Accounts.User)
IO.inspect(length(users), label: "Number of users")

if length(users) == 0 do
  IO.puts("❌ No users found! Please register a user first.")
  System.halt(1)
end

user = List.first(users)
IO.puts("✅ Found user: #{user.email} (ID: #{user.id})")

# 2. Check if we have levels
IO.puts("\n2. Checking for levels...")
levels = Repo.all(Levels.Level)
IO.inspect(length(levels), label: "Number of levels")

if length(levels) == 0 do
  IO.puts("❌ No levels found! Please run: mix run priv/repo/seeds.exs")
  System.halt(1)
end

level = List.first(levels)
IO.puts("✅ Found level: #{level.name} (ID: #{level.id})")

# 3. Try to save a test score
IO.puts("\n3. Attempting to save a test score...")
IO.puts("   User ID: #{user.id}")
IO.puts("   Level ID: #{level.id}")
IO.puts("   Time: 120 seconds")
IO.puts("   Moves: 50")

case Scores.save_score(user.id, level.id, 120, 50) do
  {:ok, score, :new_best} ->
    IO.puts("\n✅ SUCCESS! Score saved as NEW BEST!")
    IO.inspect(score, label: "Saved score")

  {:ok, score, :not_best} ->
    IO.puts("\n✅ SUCCESS! Score saved but not best")
    IO.inspect(score, label: "Saved score")

  {:error, changeset} ->
    IO.puts("\n❌ FAILED to save score!")
    IO.inspect(changeset.errors, label: "Errors")
end

# 4. Check database
IO.puts("\n4. Checking database for saved scores...")
all_scores = Repo.all(Scores.Score)
IO.inspect(length(all_scores), label: "Total scores in database")

if length(all_scores) > 0 do
  IO.puts("\n📊 All scores:")
  Enum.each(all_scores, fn score ->
    IO.puts("   - Score ID: #{score.id}, User: #{score.user_id}, Level: #{score.level_id}, Time: #{score.time_seconds}s, Moves: #{score.moves}")
  end)
end

IO.puts("\n=== Test Complete ===\n")

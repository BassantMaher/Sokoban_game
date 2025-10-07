defmodule SokobanTask1.Scores do
  @moduledoc """
  The Scores context for tracking game performance.
  """

  import Ecto.Query, warn: false
  alias SokobanTask1.Repo
  alias SokobanTask1.Scores.Score

  @doc """
  Creates a score record.
  """
  def create_score(attrs \\ %{}) do
    %Score{}
    |> Score.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Saves a score for a user, but only if it's better than their previous best.
  Returns {:ok, score} if saved, {:ok, :not_best} if not the best score.
  For anonymous users (user_id: nil), always saves.
  """
  def save_if_best(user_id, level_id, time_seconds, moves) do
    case get_user_best_score(user_id, level_id) do
      nil ->
        # No previous score, save this one
        create_score(%{
          user_id: user_id,
          level_id: level_id,
          time_seconds: time_seconds,
          moves: moves,
          completed_at: DateTime.utc_now()
        })

      best_score ->
        # Compare: lower is better (time + moves as tiebreaker)
        if is_better_score?(time_seconds, moves, best_score.time_seconds, best_score.moves) do
          create_score(%{
            user_id: user_id,
            level_id: level_id,
            time_seconds: time_seconds,
            moves: moves,
            completed_at: DateTime.utc_now()
          })
        else
          {:ok, :not_best}
        end
    end
  end

  @doc """
  Gets the best score for a user on a specific level.
  """
  def get_user_best_score(nil, _level_id), do: nil

  def get_user_best_score(user_id, level_id) do
    from(s in Score,
      where: s.user_id == ^user_id and s.level_id == ^level_id,
      order_by: [asc: s.time_seconds, asc: s.moves],
      limit: 1
    )
    |> Repo.one()
  end

  @doc """
  Gets all scores for a user on a specific level, ordered by best first.
  """
  def list_user_scores(user_id, level_id) do
    from(s in Score,
      where: s.user_id == ^user_id and s.level_id == ^level_id,
      order_by: [asc: s.time_seconds, asc: s.moves]
    )
    |> Repo.all()
  end

  @doc """
  Gets all scores for a user across all levels.
  """
  def list_user_all_scores(user_id) do
    from(s in Score,
      where: s.user_id == ^user_id,
      order_by: [asc: s.level_id, asc: s.time_seconds, asc: s.moves],
      preload: [:level_record]
    )
    |> Repo.all()
  end

  @doc """
  Gets the top N scores for a level (leaderboard).
  """
  def get_leaderboard(level_id, limit \\ 10) do
    from(s in Score,
      where: s.level_id == ^level_id and not is_nil(s.user_id),
      order_by: [asc: s.time_seconds, asc: s.moves],
      limit: ^limit,
      preload: [:user]
    )
    |> Repo.all()
  end

  @doc """
  Gets the user's rank for a specific level.
  Returns the position (1-based) or nil if no score.
  """
  def get_user_rank(user_id, level_id) do
    best_score = get_user_best_score(user_id, level_id)

    if best_score do
      # Count how many scores are better
      better_count =
        from(s in Score,
          where: s.level_id == ^level_id and not is_nil(s.user_id),
          where:
            s.time_seconds < ^best_score.time_seconds or
              (s.time_seconds == ^best_score.time_seconds and s.moves < ^best_score.moves),
          select: count(s.id),
          distinct: s.user_id
        )
        |> Repo.one()

      better_count + 1
    else
      nil
    end
  end

  # Private helper to compare scores
  defp is_better_score?(new_time, new_moves, old_time, old_moves) do
    cond do
      new_time < old_time -> true
      new_time > old_time -> false
      new_moves < old_moves -> true
      true -> false
    end
  end
end

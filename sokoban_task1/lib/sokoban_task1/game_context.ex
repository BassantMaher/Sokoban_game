defmodule SokobanTask1.GameContext do
  @moduledoc """
  The Game database context for managing levels, game sessions, and scores.
  """

  import Ecto.Query, warn: false
  alias SokobanTask1.Repo
  alias SokobanTask1.Game.{Level, GameSession, Score}
  alias SokobanTask1.Accounts

  # Level functions

  @doc """
  Creates a level with the given attributes.
  """
  def create_level(attrs \\ %{}) do
    %Level{}
    |> Level.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Gets a level by ID.
  """
  def get_level!(id) do
    Repo.get!(Level, id)
  end

  @doc """
  Lists all levels ordered by difficulty.
  """
  def list_levels do
    Level
    |> order_by([l], [asc: l.difficulty, asc: l.order])
    |> Repo.all()
  end

  @doc """
  Gets levels by difficulty.
  """
  def get_levels_by_difficulty(difficulty) do
    Level
    |> where([l], l.difficulty == ^difficulty)
    |> order_by([l], asc: l.order)
    |> Repo.all()
  end

  # Game Session functions

  @doc """
  Starts a new game session.
  """
  def start_game_session(user_id, level_id) do
    attrs = %{
      user_id: user_id,
      level_id: level_id,
      status: :in_progress,
      moves_count: 0,
      current_board: get_level!(level_id).board
    }

    %GameSession{}
    |> GameSession.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Gets an active game session for a user and level.
  """
  def get_active_game_session(user_id, level_id) do
    GameSession
    |> where([gs], gs.user_id == ^user_id and gs.level_id == ^level_id and gs.status == :in_progress)
    |> Repo.one()
  end

  @doc """
  Updates a game session with a new move.
  """
  def make_move(game_session_id, new_board, move_data) do
    game_session = Repo.get!(GameSession, game_session_id)

    move_history = game_session.move_history ++ [move_data]

    attrs = %{
      current_board: new_board,
      move_history: move_history,
      moves_count: game_session.moves_count + 1
    }

    game_session
    |> GameSession.move_changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Completes a game session.
  """
  def complete_game_session(game_session_id, final_board) do
    game_session = Repo.get!(GameSession, game_session_id)

    time_taken = DateTime.diff(DateTime.utc_now(), game_session.started_at, :second)

    attrs = %{
      status: :completed,
      completed_at: DateTime.utc_now(),
      current_board: final_board
    }

    case Repo.update(GameSession.completion_changeset(game_session, attrs)) do
      {:ok, completed_session} ->
        # Create score record
        create_score_for_session(completed_session, time_taken)

        # Update user stats
        Accounts.update_user_stats(completed_session.user_id, true)

        {:ok, completed_session}

      {:error, changeset} ->
        {:error, changeset}
    end
  end

  @doc """
  Abandons a game session.
  """
  def abandon_game_session(game_session_id) do
    game_session = Repo.get!(GameSession, game_session_id)

    attrs = %{
      status: :abandoned,
      completed_at: DateTime.utc_now()
    }

    result = game_session
    |> GameSession.completion_changeset(attrs)
    |> Repo.update()

    case result do
      {:ok, _session} ->
        # Update user stats (game played but not completed)
        Accounts.update_user_stats(game_session.user_id, false)
        result

      error ->
        error
    end
  end

  # Score functions

  @doc """
  Creates a score record for a completed game session.
  """
  def create_score_for_session(game_session, time_taken) do
    _level = get_level!(game_session.level_id)

    attrs = %{
      user_id: game_session.user_id,
      level_id: game_session.level_id,
      game_session_id: game_session.id,
      moves_count: game_session.moves_count,
      time_taken: time_taken
    }

    # Check if this is a personal best
    personal_best = is_personal_best?(game_session.user_id, game_session.level_id, attrs)
    attrs = Map.put(attrs, :is_personal_best, personal_best)

    %Score{}
    |> Score.changeset(attrs)
    |> Repo.insert()
    |> case do
      {:ok, score} ->
        if personal_best do
          # Mark previous personal bests as false
          update_previous_personal_bests(game_session.user_id, game_session.level_id, score.id)
        end
        {:ok, score}

      error ->
        error
    end
  end

  @doc """
  Gets scores for a specific level (leaderboard).
  """
  def get_level_leaderboard(level_id, limit \\ 10) do
    from(s in Score,
      join: u in assoc(s, :user),
      where: s.level_id == ^level_id and s.is_personal_best == true,
      order_by: [desc: s.score],
      limit: ^limit,
      select: %{score: s, user: u}
    )
    |> Repo.all()
  end

  @doc """
  Gets a user's scores for all levels.
  """
  def get_user_scores(user_id) do
    from(s in Score,
      join: l in assoc(s, :level),
      where: s.user_id == ^user_id and s.is_personal_best == true,
      order_by: [asc: l.difficulty, asc: l.order],
      preload: [:level]
    )
    |> Repo.all()
  end

  @doc """
  Gets user's progress statistics.
  """
  def get_user_progress(user_id) do
    total_levels = Repo.aggregate(Level, :count, :id)
    completed_levels =
      from(s in Score,
        where: s.user_id == ^user_id and s.is_personal_best == true,
        select: count(s.id)
      )
      |> Repo.one()

    total_score =
      from(s in Score,
        where: s.user_id == ^user_id and s.is_personal_best == true,
        select: sum(s.score)
      )
      |> Repo.one() || 0

    %{
      total_levels: total_levels,
      completed_levels: completed_levels,
      completion_percentage: if(total_levels > 0, do: (completed_levels / total_levels * 100) |> Float.round(1), else: 0),
      total_score: total_score
    }
  end

  # Private functions

  defp is_personal_best?(user_id, level_id, new_score_attrs) do
    case get_user_best_score(user_id, level_id) do
      nil -> true
      best_score ->
        new_score = Score.calculate_score_value(new_score_attrs.moves_count, new_score_attrs.time_taken)
        new_score > best_score.score
    end
  end

  defp get_user_best_score(user_id, level_id) do
    from(s in Score,
      where: s.user_id == ^user_id and s.level_id == ^level_id and s.is_personal_best == true,
      order_by: [desc: s.score],
      limit: 1
    )
    |> Repo.one()
  end

  defp update_previous_personal_bests(user_id, level_id, new_score_id) do
    from(s in Score,
      where: s.user_id == ^user_id and s.level_id == ^level_id and s.is_personal_best == true and s.id != ^new_score_id
    )
    |> Repo.update_all(set: [is_personal_best: false])
  end
end

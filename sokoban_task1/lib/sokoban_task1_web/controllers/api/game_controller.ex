defmodule SokobanTask1Web.API.GameController do
  use SokobanTask1Web, :controller

  alias SokobanTask1.GameContext

  @doc """
  Get all levels.
  """
  def levels(conn, _params) do
    levels = GameContext.list_levels()

    conn
    |> put_status(:ok)
    |> json(%{
      success: true,
      levels: Enum.map(levels, &format_level/1)
    })
  end

  @doc """
  Get a specific level.
  """
  def level(conn, %{"id" => level_id}) do
    level = GameContext.get_level!(level_id)

    conn
    |> put_status(:ok)
    |> json(%{
      success: true,
      level: format_level(level)
    })
  end

  @doc """
  Start a new game session.
  """
  def start_session(conn, %{"level_id" => level_id}) do
    user = conn.assigns.current_user

    case GameContext.start_game_session(user.id, level_id) do
      {:ok, session} ->
        conn
        |> put_status(:created)
        |> json(%{
          success: true,
          message: "Game session started",
          session: format_game_session(session)
        })

      {:error, changeset} ->
        errors = format_changeset_errors(changeset)

        conn
        |> put_status(:unprocessable_entity)
        |> json(%{
          success: false,
          message: "Failed to start game session",
          errors: errors
        })
    end
  end

  @doc """
  Get active game session.
  """
  def active_session(conn, %{"level_id" => level_id}) do
    user = conn.assigns.current_user

    case GameContext.get_active_game_session(user.id, level_id) do
      nil ->
        conn
        |> put_status(:not_found)
        |> json(%{success: false, message: "No active session found"})

      session ->
        conn
        |> put_status(:ok)
        |> json(%{
          success: true,
          session: format_game_session(session)
        })
    end
  end

  @doc """
  Make a move in a game session.
  """
  def make_move(conn, %{"session_id" => session_id, "board" => new_board, "move" => move_data}) do
    case GameContext.make_move(session_id, new_board, move_data) do
      {:ok, session} ->
        conn
        |> put_status(:ok)
        |> json(%{
          success: true,
          message: "Move recorded",
          session: format_game_session(session)
        })

      {:error, changeset} ->
        errors = format_changeset_errors(changeset)

        conn
        |> put_status(:unprocessable_entity)
        |> json(%{
          success: false,
          message: "Failed to record move",
          errors: errors
        })
    end
  end

  @doc """
  Complete a game session.
  """
  def complete_session(conn, %{"session_id" => session_id, "final_board" => final_board}) do
    case GameContext.complete_game_session(session_id, final_board) do
      {:ok, session} ->
        conn
        |> put_status(:ok)
        |> json(%{
          success: true,
          message: "Game completed!",
          session: format_game_session(session)
        })

      {:error, changeset} ->
        errors = format_changeset_errors(changeset)

        conn
        |> put_status(:unprocessable_entity)
        |> json(%{
          success: false,
          message: "Failed to complete game",
          errors: errors
        })
    end
  end

  @doc """
  Abandon a game session.
  """
  def abandon_session(conn, %{"session_id" => session_id}) do
    case GameContext.abandon_game_session(session_id) do
      {:ok, session} ->
        conn
        |> put_status(:ok)
        |> json(%{
          success: true,
          message: "Game abandoned",
          session: format_game_session(session)
        })

      {:error, changeset} ->
        errors = format_changeset_errors(changeset)

        conn
        |> put_status(:unprocessable_entity)
        |> json(%{
          success: false,
          message: "Failed to abandon game",
          errors: errors
        })
    end
  end

  @doc """
  Get level leaderboard.
  """
  def leaderboard(conn, %{"level_id" => level_id}) do
    limit = Map.get(conn.params, "limit", "10") |> String.to_integer()
    leaderboard = GameContext.get_level_leaderboard(level_id, limit)

    conn
    |> put_status(:ok)
    |> json(%{
      success: true,
      leaderboard: Enum.map(leaderboard, &format_leaderboard_entry/1)
    })
  end

  @doc """
  Get user's scores.
  """
  def user_scores(conn, _params) do
    user = conn.assigns.current_user
    scores = GameContext.get_user_scores(user.id)

    conn
    |> put_status(:ok)
    |> json(%{
      success: true,
      scores: Enum.map(scores, &format_score/1)
    })
  end

  @doc """
  Get user's progress.
  """
  def user_progress(conn, _params) do
    user = conn.assigns.current_user
    progress = GameContext.get_user_progress(user.id)

    conn
    |> put_status(:ok)
    |> json(%{
      success: true,
      progress: progress
    })
  end

  # Private formatting functions

  defp format_level(level) do
    %{
      id: level.id,
      name: level.name,
      difficulty: level.difficulty,
      order: level.order,
      board: level.board,
      description: level.description,
      minimum_moves: level.minimum_moves,
      created_at: level.inserted_at,
      updated_at: level.updated_at
    }
  end

  defp format_game_session(session) do
    %{
      id: session.id,
      user_id: session.user_id,
      level_id: session.level_id,
      status: session.status,
      moves_count: session.moves_count,
      current_board: session.current_board,
      move_history: session.move_history,
      started_at: session.started_at,
      completed_at: session.completed_at
    }
  end

  defp format_score(score) do
    %{
      id: score.id,
      level: format_level(score.level),
      moves_count: score.moves_count,
      time_taken: score.time_taken,
      score: score.score,
      is_personal_best: score.is_personal_best,
      created_at: score.inserted_at
    }
  end

  defp format_leaderboard_entry(%{score: score, user: user}) do
    %{
      user: %{
        id: user.id,
        username: user.username,
        display_name: user.display_name
      },
      score: score.score,
      moves_count: score.moves_count,
      time_taken: score.time_taken,
      created_at: score.inserted_at
    }
  end

  defp format_changeset_errors(changeset) do
    changeset.errors
    |> Enum.map(fn {field, {message, _}} ->
      %{field: field, message: message}
    end)
  end
end

defmodule SokobanTask1Web.AdminController do
  @moduledoc """
  Admin controller for managing levels and users.
  """
  use SokobanTask1Web, :controller

  import Ecto.Query, warn: false
  alias SokobanTask1.GameContext
  alias SokobanTask1.Game.{Level, GameSession}
  alias SokobanTask1.Accounts.User

  def dashboard(conn, _params) do
    # Get statistics for admin dashboard
    total_users = count_users()
    total_levels = count_levels()
    total_games_played = count_total_games()
    total_levels_completed = count_total_completions()

    stats = %{
      total_users: total_users,
      total_levels: total_levels,
      total_games_played: total_games_played,
      total_levels_completed: total_levels_completed
    }

    render(conn, :dashboard, stats: stats)
  end

  def users(conn, _params) do
    users = list_all_users()
    render(conn, :users, users: users)
  end

  def levels(conn, _params) do
    levels = GameContext.list_levels()
    render(conn, :levels, levels: levels)
  end

  def create_level(conn, %{"level" => level_params}) do
    case GameContext.create_level(level_params) do
      {:ok, _level} ->
        conn
        |> put_flash(:info, "Level created successfully.")
        |> redirect(to: ~p"/admin/levels")

      {:error, changeset} ->
        levels = GameContext.list_levels()
        render(conn, :levels, levels: levels, changeset: changeset)
    end
  end

  def update_level(conn, %{"id" => id, "level" => level_params}) do
    level = GameContext.get_level!(id)

    case update_level_with_params(level, level_params) do
      {:ok, _level} ->
        conn
        |> put_flash(:info, "Level updated successfully.")
        |> redirect(to: ~p"/admin/levels")

      {:error, changeset} ->
        levels = GameContext.list_levels()
        render(conn, :levels, levels: levels, changeset: changeset)
    end
  end

  def delete_level(conn, %{"id" => id}) do
    level = GameContext.get_level!(id)

    case delete_level_safe(level) do
      {:ok, _level} ->
        conn
        |> put_flash(:info, "Level deleted successfully.")
        |> redirect(to: ~p"/admin/levels")

      {:error, _changeset} ->
        conn
        |> put_flash(:error, "Cannot delete level - it may have associated game sessions.")
        |> redirect(to: ~p"/admin/levels")
    end
  end

  # Private helper functions

  defp count_users do
    from(u in User, select: count(u.id))
    |> SokobanTask1.Repo.one()
  end

  defp count_levels do
    from(l in Level, select: count(l.id))
    |> SokobanTask1.Repo.one()
  end

  defp count_total_games do
    from(gs in GameSession, select: count(gs.id))
    |> SokobanTask1.Repo.one()
  end

  defp count_total_completions do
    from(gs in GameSession, where: gs.status == :completed, select: count(gs.id))
    |> SokobanTask1.Repo.one()
  end

  defp list_all_users do
    from(u in User,
      order_by: [desc: u.inserted_at],
      select: %{
        id: u.id,
        username: u.username,
        email: u.email,
        display_name: u.display_name,
        is_admin: u.is_admin,
        is_active: u.is_active,
        levels_completed: u.levels_completed,
        games_played: u.games_played,
        total_score: u.total_score,
        inserted_at: u.inserted_at,
        last_login_at: u.last_login_at
      }
    )
    |> SokobanTask1.Repo.all()
  end

  defp update_level_with_params(level, params) do
    level
    |> Level.changeset(params)
    |> SokobanTask1.Repo.update()
  end

  defp delete_level_safe(level) do
    # Check if level has any game sessions
    sessions_count = from(gs in GameSession,
                         where: gs.level_id == ^level.id,
                         select: count(gs.id))
                    |> SokobanTask1.Repo.one()

    if sessions_count > 0 do
      {:error, :has_sessions}
    else
      SokobanTask1.Repo.delete(level)
    end
  end
end

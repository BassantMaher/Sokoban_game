defmodule SokobanTask1.Accounts do
  @moduledoc """
  The Accounts context for user management and authentication.
  """

  import Ecto.Query, warn: false
  alias SokobanTask1.Repo
  alias SokobanTask1.Accounts.User

  @doc """
  Creates a user with the given attributes.
  """
  def create_user(attrs \\ %{}) do
    %User{}
    |> User.registration_changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Gets a user by ID.
  """
  def get_user(id) do
    Repo.get(User, id)
  end

  @doc """
  Gets a user by ID, raising if not found.
  """
  def get_user!(id) do
    Repo.get!(User, id)
  end

  @doc """
  Gets a user by email.
  """
  def get_user_by_email(email) when is_binary(email) do
    Repo.get_by(User, email: email)
  end

  @doc """
  Gets a user by username.
  """
  def get_user_by_username(username) when is_binary(username) do
    Repo.get_by(User, username: username)
  end

  @doc """
  Authenticates a user with email/username and password.
  """
  def authenticate_user(email_or_username, password) when is_binary(email_or_username) and is_binary(password) do
    user = 
      case String.contains?(email_or_username, "@") do
        true -> get_user_by_email(email_or_username)
        false -> get_user_by_username(email_or_username)
      end

    case user do
      nil -> {:error, :invalid_credentials}
      user -> verify_password(user, password)
    end
  end

  @doc """
  Updates a user's profile information.
  """
  def update_user_profile(user, attrs) do
    user
    |> User.profile_changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Changes a user's password.
  """
  def change_user_password(user, attrs) do
    user
    |> User.password_changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Gets users for leaderboard with their best scores.
  """
  def get_leaderboard(limit \\ 10) do
    from(u in User,
      left_join: s in assoc(u, :scores),
      where: s.is_personal_best == true,
      group_by: u.id,
      select: %{
        user: u,
        total_score: sum(s.score),
        levels_completed: count(s.id)
      },
      order_by: [desc: sum(s.score)],
      limit: ^limit
    )
    |> Repo.all()
  end

  @doc """
  Updates user statistics after completing a level.
  """
  def update_user_stats(user_id, level_completed \\ false) do
    user = get_user!(user_id)
    
    updates = %{
      games_played: user.games_played + 1
    }
    
    updates = if level_completed do
      Map.put(updates, :levels_completed, user.levels_completed + 1)
    else
      updates
    end

    user
    |> User.stats_changeset(updates)
    |> Repo.update()
  end

  # Private functions

  defp verify_password(user, password) do
    if Pbkdf2.verify_pass(password, user.password_hash) do
      {:ok, user}
    else
      {:error, :invalid_credentials}
    end
  end
end
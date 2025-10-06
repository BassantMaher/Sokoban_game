defmodule AuthService.Accounts do
  @moduledoc """
  The Accounts context.
  """

  import Ecto.Query, warn: false
  alias SokobanTask2.Repo

  alias AuthService.Accounts.{User, Role, Score, Level}

  @doc """
  Returns the list of users.
  """
  def list_users do
    Repo.all(User) |> Repo.preload(:role)
  end

  @doc """
  Gets a single user.
  """
  def get_user!(id), do: Repo.get!(User, id) |> Repo.preload(:role)
  def get_user(id), do: Repo.get(User, id) |> Repo.preload(:role)

  @doc """
  Gets a user by email.
  """
  def get_user_by_email(email) do
    Repo.get_by(User, email: email) |> Repo.preload(:role)
  end

  @doc """
  Creates a user.
  """
  def create_user(attrs \\ %{}) do
    %User{}
    |> User.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a user.
  """
  def update_user(%User{} = user, attrs) do
    user
    |> User.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a user.
  """
  def delete_user(%User{} = user) do
    Repo.delete(user)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking user changes.
  """
  def change_user(%User{} = user, attrs \\ %{}) do
    User.changeset(user, attrs)
  end

  @doc """
  Authenticates a user by email and password.
  """
  def authenticate_user(email, password) do
    user = get_user_by_email(email)

    cond do
      user && Pbkdf2.verify_pass(password, user.password_hash) ->
        {:ok, user}

      user ->
        {:error, :invalid_password}

      true ->
        Pbkdf2.no_user_verify()
        {:error, :invalid_email}
    end
  end

  @doc """
  Returns the list of roles.
  """
  def list_roles do
    Repo.all(Role)
  end

  @doc """
  Gets a single role.
  """
  def get_role!(id), do: Repo.get!(Role, id)
  def get_role(id), do: Repo.get(Role, id)

  @doc """
  Gets a role by name.
  """
  def get_role_by_name(name) do
    Repo.get_by(Role, name: name)
  end

  @doc """
  Creates a role.
  """
  def create_role(attrs \\ %{}) do
    %Role{}
    |> Role.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Creates a score.
  """
  def create_score(attrs \\ %{}) do
    %Score{}
    |> Score.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Gets the top scores with users and levels.
  """
  def get_top_scores(limit \\ 10) do
    from(s in Score,
      join: u in User,
      on: s.user_id == u.id,
      join: r in Role,
      on: u.role_id == r.id,
      join: l in Level,
      on: s.level_id == l.id,
      where: r.name != "anonymous",
      order_by: [asc: s.moves, asc: s.time_seconds],
      limit: ^limit,
      preload: [user: {u, :role}, level: l]
    )
    |> Repo.all()
  end

  @doc """
  Creates a level.
  """
  def create_level(attrs \\ %{}) do
    %Level{}
    |> Level.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Returns the list of levels.
  """
  def list_levels do
    Repo.all(Level) |> Repo.preload(:creator)
  end

  @doc """
  Gets a single level.
  """
  def get_level!(id), do: Repo.get!(Level, id) |> Repo.preload(:creator)
  def get_level(id), do: Repo.get(Level, id) |> Repo.preload(:creator)
end

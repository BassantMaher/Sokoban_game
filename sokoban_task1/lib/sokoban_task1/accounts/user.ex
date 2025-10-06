defmodule SokobanTask1.Accounts.User do
  @moduledoc """
  User schema for Sokoban game authentication and profile management.
  """
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "users" do
    field :email, :string
    field :username, :string
    field :password, :string, virtual: true
    field :password_confirmation, :string, virtual: true
    field :password_hash, :string
    field :display_name, :string
    field :first_name, :string
    field :last_name, :string
    field :avatar_url, :string
    field :is_admin, :boolean, default: false
    field :is_active, :boolean, default: true
    field :last_login_at, :utc_datetime
    field :email_verified_at, :utc_datetime
    field :total_score, :integer, default: 0
    field :games_played, :integer, default: 0
    field :levels_completed, :integer, default: 0

    # Virtual field for login
    field :email_or_username, :string, virtual: true

    has_many :created_levels, SokobanTask1.Game.Level, foreign_key: :creator_id
    has_many :game_sessions, SokobanTask1.Game.GameSession
    has_many :scores, SokobanTask1.Game.Score

    timestamps(type: :utc_datetime)
  end

  @doc """
  Changeset for user registration.
  """
  def registration_changeset(user, attrs) do
    user
    |> cast(attrs, [:email, :username, :password, :password_confirmation, :display_name, :first_name, :last_name])
    |> validate_required([:email, :username, :password])
    |> validate_email()
    |> validate_username()
    |> validate_password()
    |> validate_password_confirmation()
    |> unique_constraint(:email)
    |> unique_constraint(:username)
    |> hash_password()
  end

  @doc """
  Changeset for login form validation.
  """
  def login_changeset(user, attrs) do
    user
    |> cast(attrs, [:email_or_username, :password])
    |> validate_required([:email_or_username, :password])
  end

  @doc """
  Changeset for user profile updates.
  """
  def profile_changeset(user, attrs) do
    user
    |> cast(attrs, [:display_name, :first_name, :last_name, :avatar_url])
    |> validate_length(:display_name, max: 50)
    |> validate_length(:first_name, max: 50)
    |> validate_length(:last_name, max: 50)
    |> validate_url(:avatar_url)
  end

  @doc """
  Changeset for password updates.
  """
  def password_changeset(user, attrs) do
    user
    |> cast(attrs, [:password])
    |> validate_required([:password])
    |> validate_password()
    |> hash_password()
  end

  @doc """
  Changeset for admin updates.
  """
  def admin_changeset(user, attrs) do
    user
    |> cast(attrs, [:is_admin, :is_active, :email_verified_at])
    |> validate_required([:is_admin, :is_active])
  end

  @doc """
  Changeset for updating login timestamp.
  """
  def login_timestamp_changeset(user) do
    user
    |> change(last_login_at: DateTime.utc_now())
  end

  @doc """
  Changeset for updating game statistics.
  """
  def stats_changeset(user, attrs) do
    user
    |> cast(attrs, [:total_score, :games_played, :levels_completed])
    |> validate_number(:total_score, greater_than_or_equal_to: 0)
    |> validate_number(:games_played, greater_than_or_equal_to: 0)
    |> validate_number(:levels_completed, greater_than_or_equal_to: 0)
  end

  # Private functions

  defp validate_email(changeset) do
    changeset
    |> validate_required([:email])
    |> validate_format(:email, ~r/^[^\s]+@[^\s]+$/, message: "must have the @ sign and no spaces")
    |> validate_length(:email, max: 160)
  end

  defp validate_username(changeset) do
    changeset
    |> validate_required([:username])
    |> validate_length(:username, min: 3, max: 20)
    |> validate_format(:username, ~r/^[a-zA-Z0-9_]+$/, message: "must contain only letters, numbers and underscores")
  end

  defp validate_password(changeset) do
    changeset
    |> validate_required([:password])
    |> validate_length(:password, min: 8, max: 72)
    |> validate_format(:password, ~r/[a-z]/, message: "at least one lower case character")
    |> validate_format(:password, ~r/[A-Z]/, message: "at least one upper case character")
    |> validate_format(:password, ~r/[!?@#$%^&*_0-9]/, message: "at least one digit or punctuation character")
  end

  defp validate_password_confirmation(changeset) do
    password = get_change(changeset, :password)
    password_confirmation = get_change(changeset, :password_confirmation)

    if password && password_confirmation && password != password_confirmation do
      add_error(changeset, :password_confirmation, "does not match password")
    else
      changeset
    end
  end

  defp validate_url(changeset, field) do
    validate_format(changeset, field, ~r/^https?:\/\/.*/, message: "must be a valid URL")
  end

  defp hash_password(changeset) do
    password = get_change(changeset, :password)

    if password && changeset.valid? do
      changeset
      |> delete_change(:password)
      |> put_change(:password_hash, Pbkdf2.hash_pwd_salt(password))
    else
      changeset
    end
  end
end

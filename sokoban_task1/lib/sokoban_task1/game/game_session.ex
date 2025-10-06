defmodule SokobanTask1.Game.GameSession do
  @moduledoc """
  GameSession schema for tracking individual game sessions.
  """
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "game_sessions" do
    field :moves_count, :integer, default: 0
    field :time_taken, :integer
    field :status, Ecto.Enum, values: [:in_progress, :completed, :abandoned], default: :in_progress
    field :completed_at, :utc_datetime
    field :started_at, :utc_datetime
    field :current_board, {:array, :string}
    field :move_history, {:array, :map}, default: []

    belongs_to :user, SokobanTask1.Accounts.User
    belongs_to :level, SokobanTask1.Game.Level
    has_many :scores, SokobanTask1.Game.Score

    timestamps(type: :utc_datetime)
  end

  @doc """
  Changeset for creating a new game session.
  """
  def changeset(game_session, attrs) do
    game_session
    |> cast(attrs, [:user_id, :level_id, :status, :moves_count, :current_board])
    |> validate_required([:user_id, :level_id])
    |> foreign_key_constraint(:user_id)
    |> foreign_key_constraint(:level_id)
    |> put_change(:status, :in_progress)
    |> put_change(:moves_count, 0)
    |> put_change(:started_at, DateTime.utc_now())
  end

  @doc """
  Changeset for creating a new game session.
  """
  def create_changeset(game_session, attrs) do
    game_session
    |> cast(attrs, [:user_id, :level_id, :board_state])
    |> validate_required([:user_id, :level_id])
    |> foreign_key_constraint(:user_id)
    |> foreign_key_constraint(:level_id)
    |> put_change(:status, :in_progress)
    |> put_change(:moves_count, 0)
    |> put_change(:move_history, "[]")
  end

  @doc """
  Changeset for making a move in the game.
  """
  def move_changeset(game_session, attrs) do
    game_session
    |> cast(attrs, [:current_board, :move_history, :moves_count])
    |> validate_number(:moves_count, greater_than_or_equal_to: 0)
  end

  @doc """
  Changeset for updating game session during play.
  """
  def play_changeset(game_session, attrs) do
    game_session
    |> cast(attrs, [:moves_count, :board_state, :move_history])
    |> validate_number(:moves_count, greater_than_or_equal_to: 0)
    |> validate_json(:board_state)
    |> validate_json(:move_history)
  end

  @doc """
  Changeset for completing a game session.
  """
  def completion_changeset(game_session, attrs) do
    game_session
    |> cast(attrs, [:status, :completed_at, :current_board])
    |> validate_required([:status])
    |> validate_inclusion(:status, [:completed, :abandoned])
  end

  @doc """
  Changeset for completing a game session.
  """
  def complete_changeset(game_session, attrs) do
    game_session
    |> cast(attrs, [:moves_count, :time_taken, :board_state, :move_history])
    |> validate_required([:moves_count, :time_taken])
    |> validate_number(:moves_count, greater_than: 0)
    |> validate_number(:time_taken, greater_than: 0)
    |> put_change(:status, :completed)
    |> put_change(:completed_at, DateTime.utc_now())
  end

  @doc """
  Changeset for abandoning a game session.
  """
  def abandon_changeset(game_session) do
    game_session
    |> change(status: :abandoned)
  end

  @doc """
  Parses move history from JSON string.
  """
  def parse_move_history(move_history) when is_binary(move_history) do
    case Jason.decode(move_history) do
      {:ok, moves} when is_list(moves) -> {:ok, moves}
      _ -> {:error, :invalid_move_history}
    end
  end

  @doc """
  Encodes move history to JSON string.
  """
  def encode_move_history(moves) when is_list(moves) do
    Jason.encode(moves)
  end

  @doc """
  Parses board state from JSON string.
  """
  def parse_board_state(board_state) when is_binary(board_state) do
    case Jason.decode(board_state) do
      {:ok, board} when is_list(board) -> {:ok, board}
      _ -> {:error, :invalid_board_state}
    end
  end

  @doc """
  Encodes board state to JSON string.
  """
  def encode_board_state(board) when is_list(board) do
    Jason.encode(board)
  end

  # Private functions

  defp validate_json(changeset, field) do
    value = get_change(changeset, field)

    if value do
      case Jason.decode(value) do
        {:ok, _} -> changeset
        {:error, _} -> add_error(changeset, field, "must be valid JSON")
      end
    else
      changeset
    end
  end
end

defmodule SokobanTask1.Game.Score do
  @moduledoc """
  Score schema for tracking game completion scores and leaderboards.
  """
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "scores" do
    field :moves_count, :integer
    field :time_taken, :integer
    field :score, :integer
    field :is_personal_best, :boolean, default: false

    belongs_to :user, SokobanTask1.Accounts.User
    belongs_to :level, SokobanTask1.Game.Level
    belongs_to :game_session, SokobanTask1.Game.GameSession

    timestamps(type: :utc_datetime)
  end

  @doc """
  Changeset for creating a new score record.
  """
  def changeset(score, attrs) do
    score
    |> cast(attrs, [:user_id, :level_id, :game_session_id, :moves_count, :time_taken, :is_personal_best])
    |> validate_required([:user_id, :level_id, :moves_count, :time_taken])
    |> validate_number(:moves_count, greater_than: 0)
    |> validate_number(:time_taken, greater_than: 0)
    |> foreign_key_constraint(:user_id)
    |> foreign_key_constraint(:level_id)
    |> foreign_key_constraint(:game_session_id)
    |> calculate_score()
  end

  @doc """
  Calculates score based on moves and time.
  Lower moves and faster time = higher score.
  """
  def calculate_score_value(moves_count, time_taken, level_minimum_moves \\ nil) do
    # Base score calculation
    # Perfect score is 10000, penalties for extra moves and time
    base_score = 10000

    # Penalty for moves (more severe if we know the minimum)
    move_penalty = case level_minimum_moves do
      nil -> moves_count * 5  # General penalty
      min_moves -> max(0, (moves_count - min_moves)) * 10  # Penalty for moves above minimum
    end

    # Penalty for time (1 point per second)
    time_penalty = time_taken

    # Ensure score is not negative
    max(0, base_score - move_penalty - time_penalty)
  end

  # Private functions

  defp calculate_score(changeset) do
    moves = get_change(changeset, :moves_count)
    time = get_change(changeset, :time_taken)

    if moves && time do
      score = calculate_score_value(moves, time)
      put_change(changeset, :score, score)
    else
      changeset
    end
  end
end

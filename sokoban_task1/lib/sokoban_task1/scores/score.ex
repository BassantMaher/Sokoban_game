defmodule SokobanTask1.Scores.Score do
  use Ecto.Schema
  import Ecto.Changeset

  schema "scores" do
    field :level, :integer
    field :time_seconds, :integer
    field :moves, :integer
    field :completed_at, :utc_datetime

    belongs_to :user, SokobanTask1.Accounts.User
    belongs_to :level_record, SokobanTask1.Levels.Level, foreign_key: :level_id

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(score, attrs) do
    score
    |> cast(attrs, [:user_id, :level, :level_id, :time_seconds, :moves, :completed_at])
    |> validate_required([:user_id, :level_id, :time_seconds, :moves, :completed_at])
    |> validate_number(:time_seconds, greater_than_or_equal_to: 0)
    |> validate_number(:moves, greater_than: 0)
    |> foreign_key_constraint(:user_id)
    |> foreign_key_constraint(:level_id)
  end
end

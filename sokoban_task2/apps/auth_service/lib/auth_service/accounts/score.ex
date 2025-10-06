defmodule AuthService.Accounts.Score do
  use Ecto.Schema
  import Ecto.Changeset

  schema "scores" do
    field :moves, :integer
    field :time_seconds, :integer

    belongs_to :user, AuthService.Accounts.User
    belongs_to :level, AuthService.Accounts.Level

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(score, attrs) do
    score
    |> cast(attrs, [:moves, :time_seconds, :user_id, :level_id])
    |> validate_required([:moves, :time_seconds, :user_id, :level_id])
    |> validate_number(:moves, greater_than: 0)
    |> validate_number(:time_seconds, greater_than: 0)
  end
end

defmodule SokobanTask1.Levels.Level do
  use Ecto.Schema
  import Ecto.Changeset

  schema "levels" do
    field :name, :string
    field :difficulty, :string
    field :board_data, {:array, :string}
    field :order, :integer
    field :description, :string

    has_many :scores, SokobanTask1.Scores.Score

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(level, attrs) do
    level
    |> cast(attrs, [:name, :difficulty, :board_data, :order, :description])
    |> validate_required([:name, :difficulty, :board_data, :order])
    |> validate_inclusion(:difficulty, ["easy", "medium", "hard", "expert"])
    |> validate_length(:name, min: 3, max: 100)
    |> unique_constraint(:order)
  end
end

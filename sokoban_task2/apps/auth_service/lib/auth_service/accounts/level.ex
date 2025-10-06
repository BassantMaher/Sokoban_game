defmodule AuthService.Accounts.Level do
  use Ecto.Schema
  import Ecto.Changeset

  schema "levels" do
    field :name, :string
    field :board_json, :string
    field :width, :integer
    field :height, :integer

    belongs_to :creator, AuthService.Accounts.User
    has_many :scores, AuthService.Accounts.Score

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(level, attrs) do
    level
    |> cast(attrs, [:name, :board_json, :width, :height, :creator_id])
    |> validate_required([:name, :board_json, :width, :height, :creator_id])
    |> validate_length(:name, min: 3, max: 100)
    |> validate_number(:width, greater_than: 3)
    |> validate_number(:height, greater_than: 3)
  end
end

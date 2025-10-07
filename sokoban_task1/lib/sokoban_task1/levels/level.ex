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
    |> sanitize_board_data()
    |> validate_required([:name, :difficulty, :board_data, :order])
    |> validate_inclusion(:difficulty, ["easy", "medium", "hard", "expert"])
    |> validate_length(:name, min: 3, max: 100)
    |> validate_board_data()
    |> unique_constraint(:order)
  end

  # Ensure board_data contains only strings
  defp sanitize_board_data(changeset) do
    case get_change(changeset, :board_data) do
      nil ->
        changeset

      board_data when is_list(board_data) ->
        sanitized =
          Enum.map(board_data, fn row ->
            cond do
              is_binary(row) -> row
              is_atom(row) -> Atom.to_string(row)
              true -> to_string(row)
            end
          end)

        put_change(changeset, :board_data, sanitized)

      _ ->
        changeset
    end
  end

  # Validate board_data structure
  defp validate_board_data(changeset) do
    validate_change(changeset, :board_data, fn :board_data, board_data ->
      cond do
        not is_list(board_data) ->
          [board_data: "must be a list of strings"]

        Enum.empty?(board_data) ->
          [board_data: "must not be empty"]

        not Enum.all?(board_data, &is_binary/1) ->
          [board_data: "all rows must be strings"]

        true ->
          []
      end
    end)
  end
end

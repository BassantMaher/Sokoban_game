defmodule SokobanTask1.Game.Level do
  @moduledoc """
  Level schema for Sokoban game levels.
  """
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "levels" do
    field :name, :string
    field :description, :string
    field :board_data, :string
    field :width, :integer
    field :height, :integer
    field :difficulty, Ecto.Enum, values: [:easy, :medium, :hard, :expert]
    field :minimum_moves, :integer
    field :is_official, :boolean, default: false
    field :is_published, :boolean, default: false
    field :play_count, :integer, default: 0
    field :completion_count, :integer, default: 0
    field :average_moves, :float

    belongs_to :creator, SokobanTask1.Accounts.User
    has_many :game_sessions, SokobanTask1.Game.GameSession
    has_many :scores, SokobanTask1.Game.Score

    timestamps(type: :utc_datetime)
  end

  @doc """
  Changeset for creating/updating levels.
  """
  def changeset(level, attrs) do
    level
    |> cast(attrs, [:name, :description, :board_data, :width, :height, :difficulty, :minimum_moves, :creator_id, :is_official, :is_published])
    |> validate_required([:name, :board_data, :width, :height, :difficulty])
    |> validate_length(:name, min: 3, max: 100)
    |> validate_length(:description, max: 500)
    |> validate_number(:width, greater_than: 0, less_than: 50)
    |> validate_number(:height, greater_than: 0, less_than: 50)
    |> validate_number(:minimum_moves, greater_than: 0)
    |> validate_board_data()
    |> foreign_key_constraint(:creator_id)
  end

  @doc """
  Changeset for updating play statistics.
  """
  def stats_changeset(level, attrs) do
    level
    |> cast(attrs, [:play_count, :completion_count, :average_moves])
    |> validate_number(:play_count, greater_than_or_equal_to: 0)
    |> validate_number(:completion_count, greater_than_or_equal_to: 0)
    |> validate_number(:average_moves, greater_than: 0)
  end

  @doc """
  Parses board data from JSON string to list of strings.
  """
  def parse_board_data(board_data) when is_binary(board_data) do
    case Jason.decode(board_data) do
      {:ok, board} when is_list(board) -> {:ok, board}
      _ -> {:error, :invalid_board_data}
    end
  end

  @doc """
  Encodes board data from list of strings to JSON string.
  """
  def encode_board_data(board) when is_list(board) do
    Jason.encode(board)
  end

  # Private functions

  defp validate_board_data(changeset) do
    board_data = get_change(changeset, :board_data)
    width = get_change(changeset, :width) || get_field(changeset, :width)
    height = get_change(changeset, :height) || get_field(changeset, :height)

    if board_data && width && height do
      case parse_board_data(board_data) do
        {:ok, board} ->
          if validate_board_structure(board, width, height) do
            changeset
          else
            add_error(changeset, :board_data, "invalid board structure")
          end
        {:error, _} ->
          add_error(changeset, :board_data, "must be valid JSON array")
      end
    else
      changeset
    end
  end

  defp validate_board_structure(board, width, height) do
    length(board) == height &&
    Enum.all?(board, fn row -> String.length(row) == width end) &&
    has_valid_elements(board)
  end

  defp has_valid_elements(board) do
    flat_board = Enum.join(board, "")

    # Check for required elements
    has_player = String.contains?(flat_board, "@")
    has_box = String.contains?(flat_board, "$")
    has_goal = String.contains?(flat_board, ".")

    # Check for valid characters only
    valid_chars = ~r/^[#@$\. ]+$/

    has_player && has_box && has_goal && Regex.match?(valid_chars, flat_board)
  end
end

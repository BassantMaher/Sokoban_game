defmodule SokobanTask1.Repo.Migrations.CreateLevelsTable do
  use Ecto.Migration

  def change do
    create table(:levels, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string, null: false
      add :description, :text
      add :board_data, :text, null: false  # JSON representation of the board
      add :width, :integer, null: false
      add :height, :integer, null: false
      add :difficulty, :string, default: "medium", null: false  # easy, medium, hard, expert
      add :minimum_moves, :integer  # Optimal solution move count
      add :creator_id, references(:users, type: :binary_id, on_delete: :nilify_all)
      add :is_official, :boolean, default: false, null: false
      add :is_published, :boolean, default: false, null: false
      add :play_count, :integer, default: 0, null: false
      add :completion_count, :integer, default: 0, null: false
      add :average_moves, :float

      timestamps(type: :utc_datetime)
    end

    create index(:levels, [:creator_id])
    create index(:levels, [:difficulty])
    create index(:levels, [:is_published])
    create index(:levels, [:is_official])
    create index(:levels, [:play_count])
    create index(:levels, [:completion_count])
    create index(:levels, [:inserted_at])
  end
end

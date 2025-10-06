defmodule SokobanTask1.Repo.Migrations.CreateScoresTable do
  use Ecto.Migration

  def change do
    create table(:scores, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :user_id, references(:users, type: :binary_id, on_delete: :delete_all), null: false
      add :level_id, references(:levels, type: :binary_id, on_delete: :delete_all), null: false
      add :game_session_id, references(:game_sessions, type: :binary_id, on_delete: :delete_all)
      add :moves_count, :integer, null: false
      add :time_taken, :integer, null: false  # Time in seconds
      add :score, :integer, null: false  # Calculated score based on moves and time
      add :is_personal_best, :boolean, default: false, null: false

      timestamps(type: :utc_datetime)
    end

    create index(:scores, [:user_id])
    create index(:scores, [:level_id])
    create index(:scores, [:score])
    create index(:scores, [:moves_count])
    create index(:scores, [:time_taken])
    create index(:scores, [:is_personal_best])
    create index(:scores, [:user_id, :level_id])
    create index(:scores, [:level_id, :score])

    # For leaderboards
    create index(:scores, [:level_id, :score, :moves_count, :time_taken])
  end
end

defmodule SokobanTask1.Repo.Migrations.CreateGameSessionsTable do
  use Ecto.Migration

  def change do
    create table(:game_sessions, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :user_id, references(:users, type: :binary_id, on_delete: :delete_all), null: false
      add :level_id, references(:levels, type: :binary_id, on_delete: :delete_all), null: false
      add :moves_count, :integer, default: 0, null: false
      add :time_taken, :integer  # Time in seconds
      add :status, :string, default: "in_progress", null: false  # in_progress, completed, abandoned
      add :completed_at, :utc_datetime
      add :started_at, :utc_datetime, default: fragment("NOW()"), null: false
      add :current_board, :text  # Current board state as JSON array
      add :move_history, :text  # Array of moves as JSON

      timestamps(type: :utc_datetime)
    end

    create index(:game_sessions, [:user_id])
    create index(:game_sessions, [:level_id])
    create index(:game_sessions, [:status])
    create index(:game_sessions, [:completed_at])
    create index(:game_sessions, [:user_id, :level_id])
  end
end

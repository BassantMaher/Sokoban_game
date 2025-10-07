defmodule SokobanTask1.Repo.Migrations.CreateScores do
  use Ecto.Migration

  def change do
    create table(:scores) do
      add :user_id, references(:users, on_delete: :delete_all), null: true
      add :level, :integer, null: false
      add :time_seconds, :integer, null: false
      add :moves, :integer, null: false
      add :completed_at, :utc_datetime, null: false

      timestamps(type: :utc_datetime)
    end

    create index(:scores, [:user_id])
    create index(:scores, [:level])
    create index(:scores, [:user_id, :level])
    # Index for finding best scores (lowest time + moves)
    create index(:scores, [:level, :time_seconds, :moves])
  end
end

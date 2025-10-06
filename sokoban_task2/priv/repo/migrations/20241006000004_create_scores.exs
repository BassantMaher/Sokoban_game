defmodule SokobanTask2.Repo.Migrations.CreateScores do
  use Ecto.Migration

  def change do
    create table(:scores) do
      add :moves, :integer, null: false
      add :time_seconds, :integer, null: false
      add :user_id, references(:users, on_delete: :nothing), null: false
      add :level_id, references(:levels, on_delete: :nothing), null: false

      timestamps(type: :utc_datetime)
    end

    create index(:scores, [:user_id])
    create index(:scores, [:level_id])
    create index(:scores, [:moves])
    create index(:scores, [:time_seconds])
  end
end

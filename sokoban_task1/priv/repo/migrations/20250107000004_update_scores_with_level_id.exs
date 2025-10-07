defmodule SokobanTask1.Repo.Migrations.UpdateScoresWithLevelId do
  use Ecto.Migration

  def change do
    alter table(:scores) do
      add :level_id, references(:levels, on_delete: :delete_all)
    end

    create index(:scores, [:level_id])
    create index(:scores, [:user_id, :level_id])
  end
end

defmodule SokobanTask2.Repo.Migrations.CreateLevels do
  use Ecto.Migration

  def change do
    create table(:levels) do
      add :name, :string, null: false
      add :board_json, :text, null: false
      add :width, :integer, null: false
      add :height, :integer, null: false
      add :creator_id, references(:users, on_delete: :nothing), null: false

      timestamps(type: :utc_datetime)
    end

    create index(:levels, [:creator_id])
  end
end

defmodule SokobanTask1.Repo.Migrations.CreateLevels do
  use Ecto.Migration

  def change do
    create table(:levels) do
      add :name, :string, null: false
      add :difficulty, :string, null: false
      add :board_data, {:array, :text}, null: false
      add :order, :integer, null: false
      add :description, :text

      timestamps(type: :utc_datetime)
    end

    create unique_index(:levels, [:order])
    create index(:levels, [:difficulty])
  end
end

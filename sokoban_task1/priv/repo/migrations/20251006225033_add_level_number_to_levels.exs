defmodule SokobanTask1.Repo.Migrations.AddLevelNumberToLevels do
  use Ecto.Migration

  def change do
    alter table(:levels) do
      add :level_number, :integer
    end
  end
end

defmodule SokobanTask2.Repo.Migrations.CreateRoles do
  use Ecto.Migration

  def change do
    create table(:roles) do
      add :name, :string, null: false

      timestamps(type: :utc_datetime)
    end

    create unique_index(:roles, [:name])
  end
end

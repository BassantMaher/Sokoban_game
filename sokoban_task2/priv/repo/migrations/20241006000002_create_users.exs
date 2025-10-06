defmodule SokobanTask2.Repo.Migrations.CreateUsers do
  use Ecto.Migration

  def change do
    create table(:users) do
      add :email, :string, null: false
      add :name, :string, null: false
      add :password_hash, :string, null: false
      add :role_id, references(:roles, on_delete: :nothing), null: false

      timestamps(type: :utc_datetime)
    end

    create unique_index(:users, [:email])
    create index(:users, [:role_id])
  end
end

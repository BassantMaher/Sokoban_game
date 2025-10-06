defmodule SokobanTask1.Repo.Migrations.CreateUsersTable do
  use Ecto.Migration

  def change do
    create table(:users, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :email, :string, null: false
      add :username, :string, null: false
      add :password_hash, :string, null: false
      add :display_name, :string
      add :first_name, :string
      add :last_name, :string
      add :avatar_url, :string
      add :is_admin, :boolean, default: false, null: false
      add :is_active, :boolean, default: true, null: false
      add :last_login_at, :utc_datetime
      add :email_verified_at, :utc_datetime
      add :total_score, :integer, default: 0, null: false
      add :games_played, :integer, default: 0, null: false
      add :levels_completed, :integer, default: 0, null: false

      timestamps(type: :utc_datetime)
    end

    create unique_index(:users, [:email])
    create unique_index(:users, [:username])
    create index(:users, [:is_active])
    create index(:users, [:total_score])
    create index(:users, [:last_login_at])
  end
end

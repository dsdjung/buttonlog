defmodule ButtonLog.Repo.Migrations.CreateUsers do
  use Ecto.Migration

  def change do
    create table(:users, primary_key: false) do
      add :id, :uuid, primary_key: true, default: fragment("gen_random_uuid()")
      add :email, :string, null: false
      add :username, :string, null: false
      add :password_hash, :string, null: false
      add :display_name, :string, null: false
      add :avatar, :text
      add :timezone, :string, default: "UTC"
      add :language, :string, default: "en"
      add :subscription_tier, :string, default: "free"
      add :subscription_expires_at, :utc_datetime
      add :default_history_sharing, :boolean, default: false
      add :allow_friend_requests, :boolean, default: true
      add :profile_visibility, :string, default: "public"
      add :activity_visibility, :string, default: "public"

      timestamps()
    end

    create unique_index(:users, [:email])
    create unique_index(:users, [:username])
    create index(:users, [:subscription_tier])
  end
end

defmodule ButtonLog.Repo.Migrations.FixOauthMigration do
  use Ecto.Migration

  def change do
    alter table(:users) do
      # OAuth provider information
      add :provider, :string
      add :provider_uid, :string
      add :provider_token, :text
      add :provider_refresh_token, :text
      add :provider_expires_at, :utc_datetime

      # Email verification status
      add :email_verified, :boolean, default: false

      # Make password_hash nullable for OAuth users
      modify :password_hash, :string, null: true
    end

    # Indexes for OAuth lookups
    create index(:users, [:provider, :provider_uid])
    create index(:users, [:email_verified])

    # Note: We'll keep the existing unique email constraint for now
    # OAuth users will need to have unique emails, which is actually good for security
  end
end

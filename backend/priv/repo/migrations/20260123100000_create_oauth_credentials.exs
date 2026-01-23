defmodule ButtonLog.Repo.Migrations.CreateOauthCredentials do
  use Ecto.Migration

  def change do
    # Create the oauth_credentials table to support multiple OAuth providers per user
    create table(:oauth_credentials, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :user_id, references(:users, type: :binary_id, on_delete: :delete_all), null: false
      add :provider, :string, null: false
      add :provider_uid, :string, null: false
      add :provider_token, :text
      add :provider_refresh_token, :text
      add :provider_expires_at, :utc_datetime

      timestamps()
    end

    # Each user can only have one credential per provider
    create unique_index(:oauth_credentials, [:user_id, :provider])
    # For looking up users by provider + uid
    create unique_index(:oauth_credentials, [:provider, :provider_uid])
    # Index for querying by user
    create index(:oauth_credentials, [:user_id])

    # Migrate existing OAuth data from users table to oauth_credentials
    execute """
    INSERT INTO oauth_credentials (id, user_id, provider, provider_uid, provider_token, provider_refresh_token, provider_expires_at, inserted_at, updated_at)
    SELECT gen_random_uuid(), id, provider, provider_uid, provider_token, provider_refresh_token, provider_expires_at, NOW(), NOW()
    FROM users
    WHERE provider IS NOT NULL AND provider_uid IS NOT NULL
    """, ""

    # Note: We keep the old columns in users table for backwards compatibility
    # They can be removed in a future migration after ensuring the new system works
  end
end

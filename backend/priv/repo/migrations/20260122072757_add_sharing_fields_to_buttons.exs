defmodule ButtonLog.Repo.Migrations.AddSharingFieldsToButtons do
  use Ecto.Migration

  def change do
    alter table(:buttons) do
      # Sharing mode: private (default), friends, invite_only, public
      add :sharing_mode, :string, default: "private"
      # Token for public link sharing
      add :share_token, :string
      # Optional expiry for public links
      add :share_token_expires_at, :utc_datetime
    end

    # Ensure share tokens are unique when set
    create unique_index(:buttons, [:share_token], where: "share_token IS NOT NULL")
  end
end

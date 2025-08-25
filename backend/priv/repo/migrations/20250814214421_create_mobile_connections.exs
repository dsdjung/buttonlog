defmodule ButtonLog.Repo.Migrations.CreateMobileConnections do
  use Ecto.Migration

  def change do
    create table(:mobile_connections, primary_key: false) do
      add :id, :uuid, primary_key: true, default: fragment("gen_random_uuid()")
      add :user_id, references(:users, type: :uuid, on_delete: :delete_all), null: false
      add :device_token, :string, null: false
      add :platform, :string, null: false
      add :app_version, :string
      add :os_version, :string
      add :is_active, :boolean, default: true
      add :last_seen_at, :utc_datetime, default: fragment("NOW()")

      timestamps()
    end

    create unique_index(:mobile_connections, [:device_token])
    create index(:mobile_connections, [:user_id])
    create index(:mobile_connections, [:platform])
    create index(:mobile_connections, [:is_active])

    # Add constraint for platform
    create constraint(:mobile_connections, :mobile_connections_platform_check,
      check: "platform IN ('android', 'iphone')")
  end
end

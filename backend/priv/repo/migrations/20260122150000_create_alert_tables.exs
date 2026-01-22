defmodule ButtonLog.Repo.Migrations.CreateAlertTables do
  use Ecto.Migration

  @doc """
  Creates the new alert tables that will replace the current notification tables.
  This is part of the alert/notification system refactoring:
  - "alerts" = friend alerts when buttons are clicked (renamed from "notifications")
  - "notifications" = external webhooks/integrations (new system)
  """

  def change do
    # Create alerts table (replaces notifications table for friend alerts)
    create table(:alerts, primary_key: false) do
      add :id, :uuid, primary_key: true, default: fragment("gen_random_uuid()")
      add :recipient_id, references(:users, type: :uuid, on_delete: :delete_all), null: false
      add :sender_id, references(:users, type: :uuid, on_delete: :delete_all)
      add :button_id, references(:buttons, type: :uuid, on_delete: :delete_all)
      add :alert_type, :string, null: false
      add :title, :string, null: false
      add :message, :string
      add :read, :boolean, default: false
      add :clicked_at, :utc_datetime
      add :metadata, :map, default: %{}

      timestamps()
    end

    # Indexes for efficient alert queries
    create index(:alerts, [:recipient_id])
    create index(:alerts, [:sender_id])
    create index(:alerts, [:button_id])
    create index(:alerts, [:read])
    create index(:alerts, [:inserted_at])

    # Create button_alert_preferences (replaces button_notification_preferences)
    create table(:button_alert_preferences, primary_key: false) do
      add :id, :uuid, primary_key: true, default: fragment("gen_random_uuid()")
      add :button_id, references(:buttons, type: :uuid, on_delete: :delete_all), null: false
      add :user_id, references(:users, type: :uuid, on_delete: :delete_all), null: false
      add :friend_id, references(:users, type: :uuid, on_delete: :delete_all), null: false
      add :enabled, :boolean, default: true
      add :alert_type, :string, default: "click"

      timestamps()
    end

    # Unique constraint to prevent duplicate preferences
    create unique_index(:button_alert_preferences, [:button_id, :user_id, :friend_id],
      name: :button_alert_preferences_unique)

    # Indexes for efficient querying
    create index(:button_alert_preferences, [:button_id])
    create index(:button_alert_preferences, [:user_id])
    create index(:button_alert_preferences, [:friend_id])
    create index(:button_alert_preferences, [:enabled])

    # Create friend_alert_permissions (replaces friend_notification_permissions)
    create table(:friend_alert_permissions, primary_key: false) do
      add :id, :uuid, primary_key: true, default: fragment("gen_random_uuid()")
      add :user_id, references(:users, type: :uuid, on_delete: :delete_all), null: false
      add :friend_id, references(:users, type: :uuid, on_delete: :delete_all), null: false
      add :can_receive_button_alerts, :boolean, default: true
      add :can_receive_friend_requests, :boolean, default: true
      add :can_receive_general_alerts, :boolean, default: true
      add :alert_frequency, :string, default: "immediate"

      timestamps()
    end

    # Unique constraint for friend alert permissions
    create unique_index(:friend_alert_permissions, [:user_id, :friend_id],
      name: :friend_alert_permissions_unique)

    # Indexes for efficient querying
    create index(:friend_alert_permissions, [:user_id])
    create index(:friend_alert_permissions, [:friend_id])
    create index(:friend_alert_permissions, [:can_receive_button_alerts])
  end
end

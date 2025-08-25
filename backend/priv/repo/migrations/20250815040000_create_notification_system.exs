defmodule ButtonLog.Repo.Migrations.CreateNotificationSystem do
  use Ecto.Migration

  def change do
    # Drop existing notifications table if it exists (it has the wrong schema)
    drop_if_exists table(:notifications)

    # Button notification preferences - which friends get notified for which buttons
    create table(:button_notification_preferences, primary_key: false) do
      add :id, :uuid, primary_key: true, default: fragment("gen_random_uuid()")
      add :button_id, references(:buttons, type: :uuid, on_delete: :delete_all), null: false
      add :user_id, references(:users, type: :uuid, on_delete: :delete_all), null: false
      add :friend_id, references(:users, type: :uuid, on_delete: :delete_all), null: false
      add :enabled, :boolean, default: true, null: false
      add :notification_type, :string, default: "click", null: false

      timestamps()
    end

    # Unique constraint to prevent duplicate preferences
    create unique_index(:button_notification_preferences, [:button_id, :user_id, :friend_id],
                       name: :button_notification_preferences_unique)

    # Indexes for efficient querying
    create index(:button_notification_preferences, [:button_id])
    create index(:button_notification_preferences, [:user_id])
    create index(:button_notification_preferences, [:friend_id])
    create index(:button_notification_preferences, [:enabled])

    # Notification history - track all sent notifications
    create table(:notifications, primary_key: false) do
      add :id, :uuid, primary_key: true, default: fragment("gen_random_uuid()")
      add :recipient_id, references(:users, type: :uuid, on_delete: :delete_all), null: false
      add :sender_id, references(:users, type: :uuid, on_delete: :delete_all), null: false
      add :button_id, references(:buttons, type: :uuid, on_delete: :delete_all), null: false
      add :notification_type, :string, null: false
      add :title, :string, null: false
      add :message, :string, null: false
      add :read, :boolean, default: false, null: false
      add :clicked_at, :utc_datetime
      add :metadata, :map, default: %{}

      timestamps()
    end

    # Indexes for notification queries
    create index(:notifications, [:recipient_id])
    create index(:notifications, [:sender_id])
    create index(:notifications, [:button_id])
    create index(:notifications, [:read])
    create index(:notifications, [:inserted_at])

    # Friend notification permissions - what types of notifications friends can receive
    create table(:friend_notification_permissions, primary_key: false) do
      add :id, :uuid, primary_key: true, default: fragment("gen_random_uuid()")
      add :user_id, references(:users, type: :uuid, on_delete: :delete_all), null: false
      add :friend_id, references(:users, type: :uuid, on_delete: :delete_all), null: false
      add :can_receive_button_notifications, :boolean, default: true, null: false
      add :can_receive_friend_requests, :boolean, default: true, null: false
      add :can_receive_general_notifications, :boolean, default: true, null: false
      add :notification_frequency, :string, default: "immediate", null: false

      timestamps()
    end

    # Unique constraint for friend permissions
    create unique_index(:friend_notification_permissions, [:user_id, :friend_id],
                       name: :friend_notification_permissions_unique)

    # Indexes for permissions
    create index(:friend_notification_permissions, [:user_id])
    create index(:friend_notification_permissions, [:friend_id])
    create index(:friend_notification_permissions, [:can_receive_button_notifications])
  end
end

defmodule ButtonLog.Repo.Migrations.MigrateToAlertTables do
  use Ecto.Migration

  @doc """
  Migrates data from old notification tables to new alert tables.
  This is part of the alert/notification system refactoring.
  """

  def up do
    # Migrate data from notifications table to alerts table
    execute """
    INSERT INTO alerts (id, recipient_id, sender_id, button_id, alert_type, title, message, read, clicked_at, metadata, inserted_at, updated_at)
    SELECT id, recipient_id, sender_id, button_id, notification_type, title, message, read, clicked_at, metadata, inserted_at, updated_at
    FROM notifications
    """

    # Migrate data from button_notification_preferences to button_alert_preferences
    execute """
    INSERT INTO button_alert_preferences (id, button_id, user_id, friend_id, enabled, alert_type, inserted_at, updated_at)
    SELECT id, button_id, user_id, friend_id, enabled, notification_type, inserted_at, updated_at
    FROM button_notification_preferences
    """

    # Migrate data from friend_notification_permissions to friend_alert_permissions
    execute """
    INSERT INTO friend_alert_permissions (id, user_id, friend_id, can_receive_button_alerts, can_receive_friend_requests, can_receive_general_alerts, alert_frequency, inserted_at, updated_at)
    SELECT id, user_id, friend_id, can_receive_button_notifications, can_receive_friend_requests, can_receive_general_notifications, notification_frequency, inserted_at, updated_at
    FROM friend_notification_permissions
    """
  end

  def down do
    # Clear data from alert tables (reverse migration)
    execute "DELETE FROM friend_alert_permissions"
    execute "DELETE FROM button_alert_preferences"
    execute "DELETE FROM alerts"
  end
end

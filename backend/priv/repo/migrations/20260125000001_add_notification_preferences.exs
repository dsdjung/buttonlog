defmodule ButtonLog.Repo.Migrations.AddNotificationPreferences do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :push_notifications_enabled, :boolean, default: true
      add :email_notifications_enabled, :boolean, default: true
      add :button_notifications, :boolean, default: true
      add :friend_notifications, :boolean, default: true
      add :system_notifications, :boolean, default: true
      add :quiet_hours_enabled, :boolean, default: false
      add :quiet_hours_start, :time
      add :quiet_hours_end, :time
    end
  end
end

defmodule ButtonLog.Repo.Migrations.RenameFriendPermissionAlerts do
  use Ecto.Migration

  @doc """
  Renames the can_receive_notifications column to can_receive_alerts in the friend_permissions table.
  This is part of the alert/notification system refactoring.
  """

  def change do
    rename table(:friend_permissions), :can_receive_notifications, to: :can_receive_alerts
  end
end

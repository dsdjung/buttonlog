defmodule ButtonLog.Repo.Migrations.RenameButtonAlertsEnabled do
  use Ecto.Migration

  @doc """
  Renames the notifications_enabled column to alerts_enabled in the buttons table.
  This is part of the alert/notification system refactoring.
  """

  def change do
    rename table(:buttons), :notifications_enabled, to: :alerts_enabled
  end
end

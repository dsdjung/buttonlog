defmodule ButtonLog.Repo.Migrations.MakeNotificationButtonIdNullable do
  use Ecto.Migration

  def change do
    # Make button_id nullable to support notifications that don't reference a button
    # (e.g., gift_button_deleted notifications where the button no longer exists)
    alter table(:notifications) do
      modify :button_id, :uuid, null: true
    end
  end
end

defmodule ButtonLog.Repo.Migrations.AddReminderFieldsToButtons do
  use Ecto.Migration

  def change do
    alter table(:buttons) do
      # Enable/disable reminder for this button
      add :reminder_enabled, :boolean, default: false

      # Hour of day to send reminder (0-23)
      add :reminder_hour, :integer

      # Days of week to send reminder (1=Monday, 7=Sunday)
      # Default to all days [1,2,3,4,5,6,7]
      add :reminder_days, {:array, :integer}, default: [1, 2, 3, 4, 5, 6, 7]

      # Timezone for interpreting reminder_hour
      add :reminder_timezone, :string, default: "UTC"

      # Track when the last reminder was sent to avoid duplicates
      add :reminder_last_sent_at, :utc_datetime
    end

    # Index for efficiently querying buttons due for reminders
    create index(:buttons, [:reminder_enabled, :reminder_hour])
  end
end

defmodule ButtonLog.Repo.Migrations.AddAutoStopMinutesToButtons do
  use Ecto.Migration

  def change do
    alter table(:buttons) do
      # Duration in minutes for auto-stop (null means no auto-stop)
      # Common values: 15, 30, 60, 120, 240, 480 (8 hours)
      add :auto_stop_minutes, :integer

      # Scheduled stop time (set when toggle button is started with auto_stop enabled)
      add :scheduled_stop_at, :utc_datetime
    end

    # Index for efficient querying of buttons that need to be auto-stopped
    create index(:buttons, [:scheduled_stop_at], where: "scheduled_stop_at IS NOT NULL")
  end
end

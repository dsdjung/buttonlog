defmodule ButtonLog.Repo.Migrations.AddCooldownHoursToButtons do
  use Ecto.Migration

  def change do
    alter table(:buttons) do
      # Cooldown in hours before button can be clicked again
      # nil = no cooldown (default), 24 = once per day, 12 = twice per day, etc.
      add :cooldown_hours, :integer
    end
  end
end

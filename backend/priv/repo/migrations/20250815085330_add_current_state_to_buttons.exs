defmodule ButtonLog.Repo.Migrations.AddCurrentStateToButtons do
  use Ecto.Migration

  def change do
    alter table(:buttons) do
      add :current_state, :string, default: "idle"
      add :state_changed_at, :utc_datetime
    end

    # Add index for querying buttons by state
    create index(:buttons, [:current_state])
  end
end

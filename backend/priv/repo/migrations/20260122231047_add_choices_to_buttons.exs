defmodule ButtonLog.Repo.Migrations.AddChoicesToButtons do
  use Ecto.Migration

  def change do
    alter table(:buttons) do
      # Array of choice options for one-time buttons (e.g., ["Yes", "No"])
      add :choices, {:array, :string}, default: nil
    end
  end
end

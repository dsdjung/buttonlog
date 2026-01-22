defmodule ButtonLog.Repo.Migrations.AddArchivedToButtons do
  use Ecto.Migration

  def change do
    alter table(:buttons) do
      add :archived, :boolean, default: false, null: false
      add :archived_at, :utc_datetime
    end

    create index(:buttons, [:archived])
    create index(:buttons, [:user_id, :archived])
  end
end

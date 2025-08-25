defmodule ButtonLog.Repo.Migrations.CreateButtons do
  use Ecto.Migration

  def change do
    create table(:buttons, primary_key: false) do
      add :id, :uuid, primary_key: true, default: fragment("gen_random_uuid()")
      add :user_id, references(:users, type: :uuid, on_delete: :delete_all), null: false
      add :name, :string, null: false
      add :description, :text
      add :type, :string, null: false
      add :icon, :string
      add :color, :string
      add :is_active, :boolean, default: true
      add :notifications_enabled, :boolean, default: true
      add :auto_stop_enabled, :boolean, default: false
      add :calendar_sync_enabled, :boolean, default: false

      timestamps()
    end

    create index(:buttons, [:user_id])
    create index(:buttons, [:type])
    create index(:buttons, [:is_active])

    # Add constraint for button type
    create constraint(:buttons, :buttons_type_check,
      check: "type IN ('instant', 'timed', 'state')")
  end
end

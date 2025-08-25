defmodule ButtonLog.Repo.Migrations.CreateButtonClicks do
  use Ecto.Migration

  def change do
    create table(:button_clicks, primary_key: false) do
      add :id, :uuid, primary_key: true, default: fragment("gen_random_uuid()")
      add :button_id, references(:buttons, type: :uuid, on_delete: :delete_all), null: false
      add :user_id, references(:users, type: :uuid, on_delete: :delete_all), null: false
      add :clicked_at, :utc_datetime, null: false
      add :duration, :integer
      add :location_lat, :decimal, precision: 10, scale: 8
      add :location_lng, :decimal, precision: 11, scale: 8
      add :device, :string
      add :platform, :string, null: false

      timestamps()
    end

    create index(:button_clicks, [:button_id])
    create index(:button_clicks, [:user_id])
    create index(:button_clicks, [:clicked_at])

    # Add constraint for platform
    create constraint(:button_clicks, :button_clicks_platform_check,
      check: "platform IN ('web', 'android', 'iphone')")
  end
end

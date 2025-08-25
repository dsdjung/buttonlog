defmodule ButtonLog.Repo.Migrations.CreateNotifications do
  use Ecto.Migration

  def change do
    create table(:notifications, primary_key: false) do
      add :id, :uuid, primary_key: true, default: fragment("gen_random_uuid()")
      add :user_id, references(:users, type: :uuid, on_delete: :delete_all), null: false
      add :sender_id, references(:users, type: :uuid, on_delete: :nilify_all)
      add :title, :string, null: false
      add :body, :text, null: false
      add :type, :string, null: false
      add :is_read, :boolean, default: false
      add :data, :map

      timestamps()
    end

    create index(:notifications, [:user_id])
    create index(:notifications, [:is_read])
    create index(:notifications, [:inserted_at])
    create index(:notifications, [:sender_id])

    # Add constraint for notification type
    create constraint(:notifications, :notifications_type_check,
      check: "type IN ('button_click', 'friend_request', 'achievement', 'reminder')")
  end
end

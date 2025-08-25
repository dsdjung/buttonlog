defmodule ButtonLog.Repo.Migrations.CreateSocialTables do
  use Ecto.Migration

  def change do
    # Friendships table
    create table(:friendships, primary_key: false) do
      add :id, :uuid, primary_key: true, default: fragment("gen_random_uuid()")
      add :user_id, references(:users, type: :uuid, on_delete: :delete_all), null: false
      add :friend_id, references(:users, type: :uuid, on_delete: :delete_all), null: false
      add :status, :string, null: false, default: "pending"

      timestamps()
    end

    create unique_index(:friendships, [:user_id, :friend_id], name: :friendships_user_friend_index)
    create index(:friendships, [:user_id])
    create index(:friendships, [:friend_id])
    create index(:friendships, [:status])

    # Add constraint for friendship status
    create constraint(:friendships, :friendships_status_check,
      check: "status IN ('pending', 'accepted', 'blocked')")

    # Add constraint to prevent self-friending
    create constraint(:friendships, :friendships_cannot_friend_self,
      check: "user_id != friend_id")

    # Friend permissions table
    create table(:friend_permissions, primary_key: false) do
      add :id, :uuid, primary_key: true, default: fragment("gen_random_uuid()")
      add :user_id, references(:users, type: :uuid, on_delete: :delete_all), null: false
      add :friend_id, references(:users, type: :uuid, on_delete: :delete_all), null: false
      add :can_view_history, :boolean, default: false
      add :can_receive_notifications, :boolean, default: true
      add :can_view_buttons, :boolean, default: true

      timestamps()
    end

    create unique_index(:friend_permissions, [:user_id, :friend_id], name: :friend_permissions_user_friend_index)
    create index(:friend_permissions, [:user_id])
    create index(:friend_permissions, [:friend_id])
  end
end

defmodule ButtonLog.Repo.Migrations.CreateButtonSharing do
  use Ecto.Migration

  def change do
    create table(:button_sharing, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :button_id, references(:buttons, on_delete: :delete_all, type: :binary_id), null: false
      add :user_id, references(:users, on_delete: :delete_all, type: :binary_id), null: false
      add :friend_id, references(:users, on_delete: :delete_all, type: :binary_id), null: false
      add :is_shared, :boolean, default: true, null: false

      timestamps()
    end

    # Unique constraint: one sharing record per button-friend pair
    create unique_index(:button_sharing, [:button_id, :friend_id], name: :button_sharing_button_friend_index)

    # Indices for efficient lookups
    create index(:button_sharing, [:button_id])
    create index(:button_sharing, [:user_id])
    create index(:button_sharing, [:friend_id])
    create index(:button_sharing, [:is_shared])
  end
end

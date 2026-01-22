defmodule ButtonLog.Repo.Migrations.AddGiftButtonFields do
  use Ecto.Migration

  def change do
    # Add fields to buttons table to track gift origin
    alter table(:buttons) do
      add :created_by_friend_id, references(:users, type: :uuid, on_delete: :nilify_all)
      add :gift_message, :text
    end

    create index(:buttons, [:created_by_friend_id])
  end
end

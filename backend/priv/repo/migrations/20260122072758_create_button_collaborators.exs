defmodule ButtonLog.Repo.Migrations.CreateButtonCollaborators do
  use Ecto.Migration

  def change do
    create table(:button_collaborators, primary_key: false) do
      add :id, :uuid, primary_key: true, default: fragment("gen_random_uuid()")
      add :button_id, references(:buttons, type: :uuid, on_delete: :delete_all), null: false
      # Nullable for tracking public link joins (user joins after clicking link)
      add :user_id, references(:users, type: :uuid, on_delete: :delete_all)
      # Permission type: "click" for now, extensible for future (view, edit, admin)
      add :permission, :string, default: "click"
      # Who invited this collaborator
      add :invited_by_id, references(:users, type: :uuid, on_delete: :nilify_all)
      # Null until accepted (for invitation flow)
      add :accepted_at, :utc_datetime

      timestamps()
    end

    # Each user can only be a collaborator once per button
    create unique_index(:button_collaborators, [:button_id, :user_id], where: "user_id IS NOT NULL")
    create index(:button_collaborators, [:user_id])
    create index(:button_collaborators, [:button_id])
  end
end

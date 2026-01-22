defmodule ButtonLog.Repo.Migrations.CreateTeams do
  use Ecto.Migration

  def change do
    # Teams table - groups of users who share buttons
    create table(:teams, primary_key: false) do
      add :id, :uuid, primary_key: true, default: fragment("gen_random_uuid()")
      add :name, :string, null: false
      add :description, :text
      add :icon, :string, default: "people"
      add :color, :string, default: "#3B82F6"
      add :owner_id, references(:users, type: :uuid, on_delete: :delete_all), null: false

      # Future-proofing for enterprise: organizations can contain multiple teams
      add :organization_id, :uuid, null: true

      timestamps()
    end

    create index(:teams, [:owner_id])
    create index(:teams, [:organization_id])

    # Team members - users who belong to a team
    create table(:team_members, primary_key: false) do
      add :id, :uuid, primary_key: true, default: fragment("gen_random_uuid()")
      add :team_id, references(:teams, type: :uuid, on_delete: :delete_all), null: false
      add :user_id, references(:users, type: :uuid, on_delete: :delete_all), null: false
      add :role, :string, null: false, default: "member"  # owner, admin, member
      add :invited_by_id, references(:users, type: :uuid, on_delete: :nilify_all)
      add :joined_at, :utc_datetime

      timestamps()
    end

    create unique_index(:team_members, [:team_id, :user_id])
    create index(:team_members, [:user_id])
    create index(:team_members, [:role])

    # Team buttons - buttons shared with a team
    create table(:team_buttons, primary_key: false) do
      add :id, :uuid, primary_key: true, default: fragment("gen_random_uuid()")
      add :team_id, references(:teams, type: :uuid, on_delete: :delete_all), null: false
      add :button_id, references(:buttons, type: :uuid, on_delete: :delete_all), null: false
      add :permission, :string, null: false, default: "click"  # view, click, admin
      add :added_by_id, references(:users, type: :uuid, on_delete: :nilify_all)

      timestamps()
    end

    create unique_index(:team_buttons, [:team_id, :button_id])
    create index(:team_buttons, [:button_id])

    # Team invitations - pending invites to join a team
    create table(:team_invitations, primary_key: false) do
      add :id, :uuid, primary_key: true, default: fragment("gen_random_uuid()")
      add :team_id, references(:teams, type: :uuid, on_delete: :delete_all), null: false
      add :inviter_id, references(:users, type: :uuid, on_delete: :delete_all), null: false
      add :invitee_id, references(:users, type: :uuid, on_delete: :delete_all)  # null for email invites
      add :email, :string  # for inviting non-users
      add :role, :string, null: false, default: "member"
      add :token, :string, null: false
      add :expires_at, :utc_datetime, null: false
      add :accepted_at, :utc_datetime
      add :declined_at, :utc_datetime

      timestamps()
    end

    create unique_index(:team_invitations, [:token])
    create index(:team_invitations, [:team_id])
    create index(:team_invitations, [:invitee_id])
    create index(:team_invitations, [:email])
  end
end

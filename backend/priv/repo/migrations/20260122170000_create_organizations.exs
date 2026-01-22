defmodule ButtonLog.Repo.Migrations.CreateOrganizations do
  use Ecto.Migration

  def change do
    # ==========================================================================
    # Organizations - Top-level enterprise entity
    # ==========================================================================
    create table(:organizations, primary_key: false) do
      add :id, :uuid, primary_key: true, default: fragment("gen_random_uuid()")
      add :name, :string, null: false
      add :slug, :string, null: false
      add :description, :text
      add :logo_url, :string
      add :website, :string

      # Enterprise features
      add :domain, :string  # For SSO domain verification (e.g., "company.com")
      add :sso_enabled, :boolean, default: false
      add :require_sso, :boolean, default: false  # Force SSO login for members

      # Settings
      add :allow_personal_teams, :boolean, default: true  # Allow members to create personal teams
      add :default_team_role, :string, default: "member"  # Default role for new team members

      # Billing
      add :billing_email, :string
      add :billing_address, :map, default: %{}
      add :tax_id, :string

      # Limits (can override subscription defaults)
      add :max_seats, :integer  # null = use subscription limit
      add :max_teams, :integer  # null = unlimited

      # Status
      add :status, :string, default: "active"  # active, suspended, cancelled

      timestamps()
    end

    create unique_index(:organizations, [:slug])
    create unique_index(:organizations, [:domain], where: "domain IS NOT NULL")
    create index(:organizations, [:status])

    # ==========================================================================
    # Organization Members - Users belonging to an organization
    # ==========================================================================
    create table(:organization_members, primary_key: false) do
      add :id, :uuid, primary_key: true, default: fragment("gen_random_uuid()")
      add :organization_id, references(:organizations, type: :uuid, on_delete: :delete_all), null: false
      add :user_id, references(:users, type: :uuid, on_delete: :delete_all), null: false

      # Roles: owner (1 per org), admin, billing_admin, member
      add :role, :string, null: false, default: "member"

      # Status: active, invited, suspended
      add :status, :string, null: false, default: "active"

      add :invited_by_id, references(:users, type: :uuid, on_delete: :nilify_all)
      add :joined_at, :utc_datetime

      timestamps()
    end

    create unique_index(:organization_members, [:organization_id, :user_id])
    create index(:organization_members, [:user_id])
    create index(:organization_members, [:organization_id, :role])
    create index(:organization_members, [:status])

    # ==========================================================================
    # Organization Invitations - Pending invites to join org
    # ==========================================================================
    create table(:organization_invitations, primary_key: false) do
      add :id, :uuid, primary_key: true, default: fragment("gen_random_uuid()")
      add :organization_id, references(:organizations, type: :uuid, on_delete: :delete_all), null: false
      add :inviter_id, references(:users, type: :uuid, on_delete: :nilify_all)

      # Can invite by user_id or email
      add :invitee_id, references(:users, type: :uuid, on_delete: :delete_all)
      add :email, :string  # For inviting non-users

      add :role, :string, null: false, default: "member"
      add :token, :string, null: false
      add :expires_at, :utc_datetime, null: false

      add :accepted_at, :utc_datetime
      add :declined_at, :utc_datetime

      timestamps()
    end

    create unique_index(:organization_invitations, [:token])
    create index(:organization_invitations, [:organization_id])
    create index(:organization_invitations, [:invitee_id])
    create index(:organization_invitations, [:email])

    # ==========================================================================
    # Organization Subscriptions - Org-level billing (separate from user subs)
    # ==========================================================================
    create table(:organization_subscriptions, primary_key: false) do
      add :id, :uuid, primary_key: true, default: fragment("gen_random_uuid()")
      add :organization_id, references(:organizations, type: :uuid, on_delete: :delete_all), null: false
      add :plan_id, references(:subscription_plans, type: :uuid, on_delete: :restrict), null: false

      # Subscription status
      add :status, :string, null: false, default: "active"  # active, past_due, cancelled, trialing

      # Billing cycle
      add :billing_cycle, :string, null: false, default: "monthly"  # monthly, yearly
      add :current_period_start, :utc_datetime
      add :current_period_end, :utc_datetime
      add :trial_ends_at, :utc_datetime

      # Seat-based pricing
      add :seats_purchased, :integer, null: false, default: 5
      add :seats_used, :integer, null: false, default: 0
      add :price_per_seat, :decimal, precision: 10, scale: 2

      # Payment provider integration
      add :payment_provider, :string  # stripe, paypal, etc.
      add :payment_provider_subscription_id, :string
      add :payment_provider_customer_id, :string

      # Cancellation tracking
      add :cancelled_at, :utc_datetime
      add :cancel_at_period_end, :boolean, default: false

      timestamps()
    end

    create unique_index(:organization_subscriptions, [:organization_id])
    create index(:organization_subscriptions, [:status])
    create index(:organization_subscriptions, [:payment_provider_subscription_id])

    # ==========================================================================
    # Update teams table to reference organizations
    # ==========================================================================
    # Note: organization_id already exists on teams table from previous migration
    # Just need to add the foreign key constraint

    alter table(:teams) do
      modify :organization_id, references(:organizations, type: :uuid, on_delete: :nilify_all),
        from: :uuid
    end

    # ==========================================================================
    # Organization Audit Log - Track important org-level actions
    # ==========================================================================
    create table(:organization_audit_logs, primary_key: false) do
      add :id, :uuid, primary_key: true, default: fragment("gen_random_uuid()")
      add :organization_id, references(:organizations, type: :uuid, on_delete: :delete_all), null: false
      add :actor_id, references(:users, type: :uuid, on_delete: :nilify_all)

      add :action, :string, null: false  # member_added, member_removed, team_created, settings_changed, etc.
      add :resource_type, :string  # user, team, subscription, settings
      add :resource_id, :uuid
      add :metadata, :map, default: %{}

      add :ip_address, :string
      add :user_agent, :string

      timestamps(updated_at: false)  # Audit logs are immutable
    end

    create index(:organization_audit_logs, [:organization_id])
    create index(:organization_audit_logs, [:actor_id])
    create index(:organization_audit_logs, [:action])
    create index(:organization_audit_logs, [:inserted_at])
  end
end

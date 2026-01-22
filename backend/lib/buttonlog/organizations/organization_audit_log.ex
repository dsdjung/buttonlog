defmodule ButtonLog.Organizations.OrganizationAuditLog do
  @moduledoc """
  Schema for organization audit logs - immutable record of important actions.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  @actions ~w(
    organization_created organization_updated organization_deleted
    member_added member_removed member_role_changed member_suspended
    team_created team_deleted team_added_to_org team_removed_from_org
    subscription_created subscription_updated subscription_cancelled
    settings_changed billing_updated
    sso_enabled sso_disabled
    invitation_sent invitation_accepted invitation_declined invitation_cancelled
  )

  @resource_types ~w(organization user team subscription settings invitation)

  schema "organization_audit_logs" do
    field :action, :string
    field :resource_type, :string
    field :resource_id, :binary_id
    field :metadata, :map, default: %{}
    field :ip_address, :string
    field :user_agent, :string

    belongs_to :organization, ButtonLog.Organizations.Organization
    belongs_to :actor, ButtonLog.Accounts.User

    timestamps(updated_at: false)
  end

  @doc false
  def changeset(audit_log, attrs) do
    audit_log
    |> cast(attrs, [:action, :resource_type, :resource_id, :metadata, :ip_address, :user_agent])
    |> validate_required([:action])
    |> validate_inclusion(:action, @actions)
    |> validate_inclusion(:resource_type, @resource_types)
  end

  @doc false
  def create_changeset(audit_log, attrs, organization_id, actor_id) do
    audit_log
    |> changeset(attrs)
    |> put_change(:organization_id, organization_id)
    |> put_change(:actor_id, actor_id)
  end

  @doc """
  Returns the list of valid actions.
  """
  def actions, do: @actions

  @doc """
  Returns the list of valid resource types.
  """
  def resource_types, do: @resource_types
end

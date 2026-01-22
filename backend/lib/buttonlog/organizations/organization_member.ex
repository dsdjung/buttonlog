defmodule ButtonLog.Organizations.OrganizationMember do
  @moduledoc """
  Schema for organization members - users who belong to an organization.

  Roles:
  - owner: Full control, can delete org, transfer ownership
  - admin: Can manage members and teams, but not billing or org settings
  - billing_admin: Can manage billing and subscription only
  - member: Basic access to org resources
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  @roles ~w(owner admin billing_admin member)
  @statuses ~w(active invited suspended)

  schema "organization_members" do
    field :role, :string, default: "member"
    field :status, :string, default: "active"
    field :joined_at, :utc_datetime

    belongs_to :organization, ButtonLog.Organizations.Organization
    belongs_to :user, ButtonLog.Accounts.User
    belongs_to :invited_by, ButtonLog.Accounts.User

    timestamps()
  end

  @doc false
  def changeset(member, attrs) do
    member
    |> cast(attrs, [:role, :status, :joined_at])
    |> validate_required([:role, :status])
    |> validate_inclusion(:role, @roles)
    |> validate_inclusion(:status, @statuses)
  end

  @doc false
  def create_changeset(member, attrs, organization_id, user_id, invited_by_id \\ nil) do
    member
    |> changeset(attrs)
    |> put_change(:organization_id, organization_id)
    |> put_change(:user_id, user_id)
    |> put_change(:invited_by_id, invited_by_id)
    |> put_change(:joined_at, DateTime.utc_now() |> DateTime.truncate(:second))
    |> unique_constraint([:organization_id, :user_id], message: "user is already a member of this organization")
  end

  @doc """
  Returns the list of valid roles.
  """
  def roles, do: @roles

  @doc """
  Returns the list of valid statuses.
  """
  def statuses, do: @statuses

  @doc """
  Checks if a role has admin privileges (owner or admin).
  """
  def is_admin?(role) when role in ["owner", "admin"], do: true
  def is_admin?(_role), do: false

  @doc """
  Checks if a role can manage billing.
  """
  def can_manage_billing?(role) when role in ["owner", "billing_admin"], do: true
  def can_manage_billing?(_role), do: false

  @doc """
  Checks if a role is the owner role.
  """
  def is_owner?(role), do: role == "owner"
end

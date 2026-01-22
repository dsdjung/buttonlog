defmodule ButtonLog.Organizations.OrganizationInvitation do
  @moduledoc """
  Schema for organization invitations - pending invites to join an organization.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  # Default expiration: 7 days
  @default_expiration_days 7

  schema "organization_invitations" do
    field :email, :string
    field :role, :string, default: "member"
    field :token, :string
    field :expires_at, :utc_datetime
    field :accepted_at, :utc_datetime
    field :declined_at, :utc_datetime

    belongs_to :organization, ButtonLog.Organizations.Organization
    belongs_to :inviter, ButtonLog.Accounts.User
    belongs_to :invitee, ButtonLog.Accounts.User

    timestamps()
  end

  @doc false
  def changeset(invitation, attrs) do
    invitation
    |> cast(attrs, [:email, :role, :expires_at, :accepted_at, :declined_at])
    |> validate_required([:role])
    |> validate_inclusion(:role, ButtonLog.Organizations.OrganizationMember.roles())
    |> validate_format(:email, ~r/^[^\s]+@[^\s]+$/, message: "must be a valid email")
    |> validate_invitee_or_email()
  end

  @doc false
  def create_changeset(invitation, attrs, organization_id, inviter_id, invitee_id \\ nil) do
    invitation
    |> cast(attrs, [:email, :role, :expires_at])
    |> validate_required([:role])
    |> validate_inclusion(:role, ButtonLog.Organizations.OrganizationMember.roles())
    |> put_change(:organization_id, organization_id)
    |> put_change(:inviter_id, inviter_id)
    |> put_change(:invitee_id, invitee_id)
    |> put_change(:token, generate_token())
    |> put_change(:expires_at, default_expiration())
    |> validate_invitee_or_email()
    |> maybe_validate_email()
  end

  defp maybe_validate_email(changeset) do
    email = get_field(changeset, :email)
    if email do
      validate_format(changeset, :email, ~r/^[^\s]+@[^\s]+$/, message: "must be a valid email")
    else
      changeset
    end
  end

  @doc false
  def accept_changeset(invitation) do
    invitation
    |> change(accepted_at: DateTime.utc_now() |> DateTime.truncate(:second))
  end

  @doc false
  def decline_changeset(invitation) do
    invitation
    |> change(declined_at: DateTime.utc_now() |> DateTime.truncate(:second))
  end

  defp validate_invitee_or_email(changeset) do
    invitee_id = get_field(changeset, :invitee_id)
    email = get_field(changeset, :email)

    if is_nil(invitee_id) and is_nil(email) do
      add_error(changeset, :email, "either invitee_id or email must be provided")
    else
      changeset
    end
  end

  defp generate_token do
    :crypto.strong_rand_bytes(32) |> Base.url_encode64(padding: false)
  end

  defp default_expiration do
    DateTime.utc_now()
    |> DateTime.add(@default_expiration_days * 24 * 60 * 60, :second)
    |> DateTime.truncate(:second)
  end

  @doc """
  Checks if an invitation is still valid (not expired, not accepted, not declined).
  """
  def valid?(%__MODULE__{} = invitation) do
    is_nil(invitation.accepted_at) and
    is_nil(invitation.declined_at) and
    DateTime.compare(invitation.expires_at, DateTime.utc_now()) == :gt
  end
end

defmodule ButtonLog.Teams.TeamInvitation do
  @moduledoc """
  Schema for team invitations - pending invites to join a team.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  @roles ~w(admin member)

  schema "team_invitations" do
    field :email, :string
    field :role, :string, default: "member"
    field :token, :string
    field :expires_at, :utc_datetime
    field :accepted_at, :utc_datetime
    field :declined_at, :utc_datetime

    belongs_to :team, ButtonLog.Teams.Team
    belongs_to :inviter, ButtonLog.Accounts.User
    belongs_to :invitee, ButtonLog.Accounts.User

    timestamps()
  end

  @doc false
  def changeset(invitation, attrs) do
    invitation
    |> cast(attrs, [:email, :role, :expires_at])
    |> validate_required([:role])
    |> validate_inclusion(:role, @roles)
    |> validate_format(:email, ~r/@/, message: "must be a valid email")
  end

  @doc false
  def create_changeset(invitation, attrs, team_id, inviter_id, invitee_id \\ nil) do
    token = generate_token()
    expires_at = DateTime.utc_now() |> DateTime.add(7, :day) |> DateTime.truncate(:second)

    invitation
    |> changeset(attrs)
    |> put_change(:team_id, team_id)
    |> put_change(:inviter_id, inviter_id)
    |> put_change(:invitee_id, invitee_id)
    |> put_change(:token, token)
    |> put_change(:expires_at, expires_at)
    |> unique_constraint(:token)
  end

  @doc """
  Marks the invitation as accepted.
  """
  def accept_changeset(invitation) do
    invitation
    |> change()
    |> put_change(:accepted_at, DateTime.utc_now() |> DateTime.truncate(:second))
  end

  @doc """
  Marks the invitation as declined.
  """
  def decline_changeset(invitation) do
    invitation
    |> change()
    |> put_change(:declined_at, DateTime.utc_now() |> DateTime.truncate(:second))
  end

  @doc """
  Checks if the invitation is still valid (not expired, not accepted/declined).
  """
  def valid?(invitation) do
    is_nil(invitation.accepted_at) &&
      is_nil(invitation.declined_at) &&
      DateTime.compare(invitation.expires_at, DateTime.utc_now()) == :gt
  end

  defp generate_token do
    :crypto.strong_rand_bytes(32) |> Base.url_encode64(padding: false)
  end
end

defmodule ButtonLog.Teams.TeamMember do
  @moduledoc """
  Schema for team members - users who belong to a team.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  @roles ~w(owner admin member)

  schema "team_members" do
    field :role, :string, default: "member"
    field :joined_at, :utc_datetime

    belongs_to :team, ButtonLog.Teams.Team
    belongs_to :user, ButtonLog.Accounts.User
    belongs_to :invited_by, ButtonLog.Accounts.User

    timestamps()
  end

  @doc false
  def changeset(member, attrs) do
    member
    |> cast(attrs, [:role, :joined_at])
    |> validate_required([:role])
    |> validate_inclusion(:role, @roles)
  end

  @doc false
  def create_changeset(member, attrs, team_id, user_id, invited_by_id \\ nil) do
    member
    |> changeset(attrs)
    |> put_change(:team_id, team_id)
    |> put_change(:user_id, user_id)
    |> put_change(:invited_by_id, invited_by_id)
    |> put_change(:joined_at, DateTime.utc_now() |> DateTime.truncate(:second))
    |> unique_constraint([:team_id, :user_id], message: "user is already a member of this team")
  end

  @doc """
  Returns the list of valid roles.
  """
  def roles, do: @roles

  @doc """
  Checks if a role has admin privileges (owner or admin).
  """
  def is_admin?(role) when role in ["owner", "admin"], do: true
  def is_admin?(_role), do: false

  @doc """
  Checks if a role is the owner role.
  """
  def is_owner?(role), do: role == "owner"
end

defmodule ButtonLog.Teams.Team do
  @moduledoc """
  Schema for teams - groups of users who share buttons together.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "teams" do
    field :name, :string
    field :description, :string
    field :icon, :string, default: "people"
    field :color, :string, default: "#3B82F6"

    # Future-proofing for enterprise
    field :organization_id, :binary_id

    belongs_to :owner, ButtonLog.Accounts.User
    has_many :members, ButtonLog.Teams.TeamMember
    has_many :team_buttons, ButtonLog.Teams.TeamButton
    has_many :invitations, ButtonLog.Teams.TeamInvitation

    # Through associations
    has_many :users, through: [:members, :user]
    has_many :buttons, through: [:team_buttons, :button]

    timestamps()
  end

  @doc false
  def changeset(team, attrs) do
    team
    |> cast(attrs, [:name, :description, :icon, :color, :organization_id])
    |> validate_required([:name])
    |> validate_length(:name, min: 1, max: 100)
    |> validate_length(:description, max: 500)
    |> validate_color(:color)
  end

  @doc false
  def create_changeset(team, attrs, owner_id) do
    team
    |> changeset(attrs)
    |> put_change(:owner_id, owner_id)
  end

  defp validate_color(changeset, field) do
    validate_change(changeset, field, fn _, color ->
      if Regex.match?(~r/^#[0-9A-Fa-f]{6}$/, color) do
        []
      else
        [{field, "must be a valid hex color (e.g., #3B82F6)"}]
      end
    end)
  end
end

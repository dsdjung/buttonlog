defmodule ButtonLog.Teams.TeamButton do
  @moduledoc """
  Schema for team buttons - buttons shared with a team.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  @permissions ~w(view click admin)

  schema "team_buttons" do
    field :permission, :string, default: "click"

    belongs_to :team, ButtonLog.Teams.Team
    belongs_to :button, ButtonLog.Buttons.Button
    belongs_to :added_by, ButtonLog.Accounts.User

    timestamps()
  end

  @doc false
  def changeset(team_button, attrs) do
    team_button
    |> cast(attrs, [:permission])
    |> validate_required([:permission])
    |> validate_inclusion(:permission, @permissions)
  end

  @doc false
  def create_changeset(team_button, attrs, team_id, button_id, added_by_id) do
    team_button
    |> changeset(attrs)
    |> put_change(:team_id, team_id)
    |> put_change(:button_id, button_id)
    |> put_change(:added_by_id, added_by_id)
    |> unique_constraint([:team_id, :button_id], message: "button is already shared with this team")
  end

  @doc """
  Returns the list of valid permissions.
  """
  def permissions, do: @permissions

  @doc """
  Checks if a permission allows clicking the button.
  """
  def can_click?(permission) when permission in ["click", "admin"], do: true
  def can_click?(_permission), do: false

  @doc """
  Checks if a permission allows admin actions (edit, remove).
  """
  def can_admin?(permission), do: permission == "admin"
end

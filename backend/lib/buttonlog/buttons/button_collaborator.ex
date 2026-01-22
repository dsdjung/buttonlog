defmodule ButtonLog.Buttons.ButtonCollaborator do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "button_collaborators" do
    field :permission, :string, default: "click"
    field :accepted_at, :utc_datetime

    belongs_to :button, ButtonLog.Buttons.Button
    belongs_to :user, ButtonLog.Accounts.User
    belongs_to :invited_by, ButtonLog.Accounts.User

    timestamps()
  end

  @doc false
  def changeset(collaborator, attrs) do
    collaborator
    |> cast(attrs, [:button_id, :user_id, :permission, :invited_by_id, :accepted_at])
    |> validate_required([:button_id, :permission])
    |> validate_inclusion(:permission, ["click", "view", "admin"])
    |> foreign_key_constraint(:button_id)
    |> foreign_key_constraint(:user_id)
    |> foreign_key_constraint(:invited_by_id)
    |> unique_constraint([:button_id, :user_id])
  end
end

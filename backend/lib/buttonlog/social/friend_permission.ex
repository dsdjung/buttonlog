defmodule ButtonLog.Social.FriendPermission do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "friend_permissions" do
    field :can_view_history, :boolean
    field :can_receive_alerts, :boolean
    field :can_view_buttons, :boolean

    # Relationships
    belongs_to :user, ButtonLog.Accounts.User
    belongs_to :friend, ButtonLog.Accounts.User

    timestamps()
  end

  def changeset(permission, attrs) do
    permission
    |> cast(attrs, [:user_id, :friend_id, :can_view_history, :can_receive_alerts, :can_view_buttons])
    |> validate_required([:user_id, :friend_id])
    |> unique_constraint([:user_id, :friend_id], name: :friend_permissions_user_friend_index)
  end

  def create_changeset(permission, attrs, user_id, friend_id) do
    permission
    |> cast(attrs, [:can_view_history, :can_receive_alerts, :can_view_buttons])
    |> put_change(:user_id, user_id)
    |> put_change(:friend_id, friend_id)
    |> put_change(:can_view_history, Map.get(attrs, :can_view_history, true))
    |> put_change(:can_receive_alerts, Map.get(attrs, :can_receive_alerts, true))
    |> put_change(:can_view_buttons, Map.get(attrs, :can_view_buttons, true))
    |> validate_required([:user_id, :friend_id])
    |> unique_constraint([:user_id, :friend_id], name: :friend_permissions_user_friend_index)
  end
end



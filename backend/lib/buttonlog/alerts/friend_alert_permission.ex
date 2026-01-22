defmodule ButtonLog.Alerts.FriendAlertPermission do
  @moduledoc """
  Schema for friend-level alert permissions.
  Controls what types of alerts a friend can receive from a user.
  This replaces the old FriendNotificationPermission schema.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "friend_alert_permissions" do
    field :can_receive_button_alerts, :boolean, default: true
    field :can_receive_friend_requests, :boolean, default: true
    field :can_receive_general_alerts, :boolean, default: true
    field :alert_frequency, :string, default: "immediate"

    # Relationships
    belongs_to :user, ButtonLog.Accounts.User
    belongs_to :friend, ButtonLog.Accounts.User

    timestamps()
  end

  def changeset(permission, attrs) do
    permission
    |> cast(attrs, [:can_receive_button_alerts, :can_receive_friend_requests,
                    :can_receive_general_alerts, :alert_frequency])
    |> validate_required([:can_receive_button_alerts, :can_receive_friend_requests,
                         :can_receive_general_alerts, :alert_frequency])
    |> validate_inclusion(:alert_frequency, ["immediate", "hourly", "daily", "weekly"])
    |> unique_constraint([:user_id, :friend_id],
      name: :friend_alert_permissions_unique)
  end

  def create_changeset(permission, attrs, user_id, friend_id) do
    permission
    |> changeset(attrs)
    |> put_change(:user_id, user_id)
    |> put_change(:friend_id, friend_id)
  end
end

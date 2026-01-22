defmodule ButtonLog.Alerts.Alert do
  @moduledoc """
  Schema for in-app alerts sent to users (friend alerts for button clicks, etc).
  This replaces the old Notification schema for friend-to-friend alerts.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "alerts" do
    field :alert_type, :string
    field :title, :string
    field :message, :string
    field :read, :boolean, default: false
    field :clicked_at, :utc_datetime
    field :metadata, :map, default: %{}

    # Relationships
    belongs_to :recipient, ButtonLog.Accounts.User
    belongs_to :sender, ButtonLog.Accounts.User
    belongs_to :button, ButtonLog.Buttons.Button

    timestamps()
  end

  @valid_alert_types [
    "button_click", "button_created", "friend_request", "general",
    "gift_button_received", "gift_button_clicked", "gift_button_deleted", "gift_button_sent",
    "one_time_button_completed",
    "support_ticket_reply", "support_ticket_status_update"
  ]

  def changeset(alert, attrs) do
    alert
    |> cast(attrs, [:alert_type, :title, :message, :read, :clicked_at, :metadata])
    |> validate_required([:alert_type, :title])
    |> validate_inclusion(:alert_type, @valid_alert_types)
  end

  def create_changeset(alert, attrs, recipient_id, sender_id, button_id) do
    alert
    |> changeset(attrs)
    |> put_change(:recipient_id, recipient_id)
    |> put_change(:sender_id, sender_id)
    |> put_change(:button_id, button_id)
  end
end

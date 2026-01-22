defmodule ButtonLog.Notifications.Notification do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "notifications" do
    field :notification_type, :string
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

  def changeset(notification, attrs) do
    notification
    |> cast(attrs, [:notification_type, :title, :message, :read, :clicked_at, :metadata])
    |> validate_required([:notification_type, :title, :message])
    |> validate_inclusion(:notification_type, [
      "button_click", "button_created", "friend_request", "general",
      "gift_button_received", "gift_button_clicked", "gift_button_deleted", "gift_button_sent"
    ])
  end

  def create_changeset(notification, attrs, recipient_id, sender_id, button_id) do
    notification
    |> changeset(attrs)
    |> put_change(:recipient_id, recipient_id)
    |> put_change(:sender_id, sender_id)
    |> put_change(:button_id, button_id)
  end
end

defmodule ButtonLog.NotificationsWebhook.NotificationDelivery do
  @moduledoc """
  Schema for tracking webhook notification delivery attempts.
  Logs all attempts to send notifications to external endpoints.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  @valid_channels ["webhook", "sms", "email", "discord", "slack"]
  @valid_statuses ["pending", "sent", "failed"]

  schema "notification_deliveries" do
    field :channel, :string
    field :destination, :string
    field :payload, :map
    field :status, :string, default: "pending"
    field :response_code, :integer
    field :response_body, :string
    field :error_message, :string
    field :attempts, :integer, default: 0
    field :delivered_at, :utc_datetime

    # Relationships
    belongs_to :user, ButtonLog.Accounts.User
    belongs_to :button, ButtonLog.Buttons.Button
    belongs_to :button_click, ButtonLog.Buttons.ButtonClick

    timestamps()
  end

  def changeset(delivery, attrs) do
    delivery
    |> cast(attrs, [
      :channel,
      :destination,
      :payload,
      :status,
      :response_code,
      :response_body,
      :error_message,
      :attempts,
      :delivered_at
    ])
    |> validate_required([:channel, :destination])
    |> validate_inclusion(:channel, @valid_channels)
    |> validate_inclusion(:status, @valid_statuses)
  end

  def create_changeset(delivery, attrs, user_id, button_id, button_click_id) do
    delivery
    |> changeset(attrs)
    |> put_change(:user_id, user_id)
    |> put_change(:button_id, button_id)
    |> put_change(:button_click_id, button_click_id)
  end

  def mark_sent_changeset(delivery, response_code, response_body) do
    delivery
    |> change()
    |> put_change(:status, "sent")
    |> put_change(:response_code, response_code)
    |> put_change(:response_body, response_body)
    |> put_change(:delivered_at, DateTime.utc_now())
    |> put_change(:attempts, delivery.attempts + 1)
  end

  def mark_failed_changeset(delivery, error_message, response_code \\ nil, response_body \\ nil) do
    delivery
    |> change()
    |> put_change(:status, "failed")
    |> put_change(:error_message, error_message)
    |> put_change(:response_code, response_code)
    |> put_change(:response_body, response_body)
    |> put_change(:attempts, delivery.attempts + 1)
  end

  def increment_attempts_changeset(delivery) do
    delivery
    |> change()
    |> put_change(:attempts, delivery.attempts + 1)
  end
end

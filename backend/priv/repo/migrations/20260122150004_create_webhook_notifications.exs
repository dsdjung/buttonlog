defmodule ButtonLog.Repo.Migrations.CreateWebhookNotifications do
  use Ecto.Migration

  @doc """
  Creates tables for the new notification system (external webhooks/integrations).
  This allows users to send button click data to external HTTP endpoints,
  with future extensibility for SMS, email, Discord, Slack, etc.
  """

  def change do
    # Account-level webhook/notification settings
    create table(:user_notification_settings, primary_key: false) do
      add :id, :uuid, primary_key: true, default: fragment("gen_random_uuid()")
      add :user_id, references(:users, type: :uuid, on_delete: :delete_all), null: false
      add :default_webhook_url, :string
      add :default_webhook_enabled, :boolean, default: false
      add :webhook_secret, :string
      add :retry_failed, :boolean, default: true
      add :max_retries, :integer, default: 3

      timestamps()
    end

    create unique_index(:user_notification_settings, [:user_id])

    # Per-button webhook/notification settings (overrides account defaults)
    create table(:button_notification_settings, primary_key: false) do
      add :id, :uuid, primary_key: true, default: fragment("gen_random_uuid()")
      add :button_id, references(:buttons, type: :uuid, on_delete: :delete_all), null: false
      add :webhook_url, :string
      add :webhook_enabled, :boolean
      add :include_metadata, :boolean, default: true

      timestamps()
    end

    create unique_index(:button_notification_settings, [:button_id])

    # Notification delivery log - track all webhook/notification deliveries
    create table(:notification_deliveries, primary_key: false) do
      add :id, :uuid, primary_key: true, default: fragment("gen_random_uuid()")
      add :user_id, references(:users, type: :uuid, on_delete: :delete_all), null: false
      add :button_id, references(:buttons, type: :uuid, on_delete: :delete_all)
      add :button_click_id, references(:button_clicks, type: :uuid, on_delete: :delete_all)
      add :channel, :string, null: false  # "webhook", future: "sms", "email", "discord", "slack"
      add :destination, :string, null: false
      add :payload, :map
      add :status, :string, default: "pending"  # pending, sent, failed
      add :response_code, :integer
      add :response_body, :text
      add :error_message, :text
      add :attempts, :integer, default: 0
      add :delivered_at, :utc_datetime

      timestamps()
    end

    create index(:notification_deliveries, [:user_id])
    create index(:notification_deliveries, [:button_id])
    create index(:notification_deliveries, [:status])
    create index(:notification_deliveries, [:channel])
    create index(:notification_deliveries, [:inserted_at])

    # Add constraint for delivery status
    create constraint(:notification_deliveries, :notification_deliveries_status_check,
      check: "status IN ('pending', 'sent', 'failed')")

    # Add constraint for channel type (extensible for future channels)
    create constraint(:notification_deliveries, :notification_deliveries_channel_check,
      check: "channel IN ('webhook', 'sms', 'email', 'discord', 'slack')")
  end
end

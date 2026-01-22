defmodule ButtonLog.NotificationsWebhook do
  @moduledoc """
  The NotificationsWebhook context.

  Handles external webhook notifications - sending button click data to HTTP endpoints.
  This is the new notification system for external integrations (webhook, and future: SMS, email, Discord, Slack).

  Note: For in-app friend alerts, see ButtonLog.Alerts.
  """

  import Ecto.Query, warn: false
  require Logger

  alias ButtonLog.Repo
  alias ButtonLog.NotificationsWebhook.{
    UserNotificationSettings,
    ButtonNotificationSettings,
    NotificationDelivery,
    WebhookService
  }

  # User Notification Settings

  @doc """
  Gets notification settings for a user.
  Returns nil if no settings exist.
  """
  def get_user_settings(user_id) do
    Repo.get_by(UserNotificationSettings, user_id: user_id)
  end

  @doc """
  Gets or creates notification settings for a user.
  """
  def get_or_create_user_settings(user_id) do
    case get_user_settings(user_id) do
      nil ->
        %UserNotificationSettings{}
        |> UserNotificationSettings.create_changeset(%{}, user_id)
        |> Repo.insert()

      settings ->
        {:ok, settings}
    end
  end

  @doc """
  Updates notification settings for a user.
  Creates settings if they don't exist.
  """
  def update_user_settings(user_id, attrs) do
    case get_user_settings(user_id) do
      nil ->
        %UserNotificationSettings{}
        |> UserNotificationSettings.create_changeset(attrs, user_id)
        |> Repo.insert()

      settings ->
        settings
        |> UserNotificationSettings.changeset(attrs)
        |> Repo.update()
    end
  end

  # Button Notification Settings

  @doc """
  Gets notification settings for a button.
  Returns nil if no settings exist.
  """
  def get_button_settings(button_id) do
    Repo.get_by(ButtonNotificationSettings, button_id: button_id)
  end

  @doc """
  Updates notification settings for a button.
  Creates settings if they don't exist.
  """
  def update_button_settings(button_id, attrs) do
    case get_button_settings(button_id) do
      nil ->
        %ButtonNotificationSettings{}
        |> ButtonNotificationSettings.create_changeset(attrs, button_id)
        |> Repo.insert()

      settings ->
        settings
        |> ButtonNotificationSettings.changeset(attrs)
        |> Repo.update()
    end
  end

  @doc """
  Deletes notification settings for a button.
  """
  def delete_button_settings(button_id) do
    case get_button_settings(button_id) do
      nil -> {:ok, nil}
      settings -> Repo.delete(settings)
    end
  end

  # Notification Delivery

  @doc """
  Lists delivery history for a user.
  """
  def list_deliveries(user_id, limit \\ 50, offset \\ 0) do
    Repo.all(
      from d in NotificationDelivery,
        where: d.user_id == ^user_id,
        order_by: [desc: d.inserted_at],
        limit: ^limit,
        offset: ^offset,
        preload: [:button, :button_click]
    )
  end

  @doc """
  Gets a specific delivery by ID.
  """
  def get_delivery(delivery_id) do
    Repo.get(NotificationDelivery, delivery_id)
    |> Repo.preload([:button, :button_click])
  end

  @doc """
  Gets pending deliveries that need to be retried.
  """
  def get_pending_deliveries(max_attempts \\ 3) do
    Repo.all(
      from d in NotificationDelivery,
        where: d.status == "failed" and d.attempts < ^max_attempts,
        order_by: [asc: d.inserted_at],
        preload: [:button, :button_click, :user]
    )
  end

  @doc """
  Creates a new delivery record.
  """
  def create_delivery(attrs, user_id, button_id, button_click_id) do
    %NotificationDelivery{}
    |> NotificationDelivery.create_changeset(attrs, user_id, button_id, button_click_id)
    |> Repo.insert()
  end

  # Main Send Functions

  @doc """
  Sends a webhook notification for a button click.
  Uses the button's settings if available, otherwise falls back to user settings.
  """
  def send_button_click_notification(click, button, user) do
    Logger.debug("Checking webhook notification for button click: button_id=#{button.id}")

    # Get effective webhook settings
    {webhook_url, webhook_enabled, include_metadata, secret} = get_effective_settings(button.user_id, button.id)

    if webhook_enabled && webhook_url do
      Logger.info("Sending webhook notification for button #{button.id}")

      # Build payload
      payload = WebhookService.build_button_click_payload(click, button, user, include_metadata: include_metadata)

      # Create delivery record
      {:ok, delivery} = create_delivery(
        %{
          channel: "webhook",
          destination: webhook_url,
          payload: payload,
          status: "pending"
        },
        user.id,
        button.id,
        click.id
      )

      # Send webhook asynchronously
      Task.start(fn ->
        WebhookService.send_webhook(delivery, webhook_url, payload, secret: secret)
      end)

      {:ok, :sent}
    else
      Logger.debug("Webhook notifications disabled for button #{button.id}")
      {:ok, :disabled}
    end
  end

  @doc """
  Sends a test webhook to verify configuration.
  """
  def send_test_webhook(user_id, button_id \\ nil) do
    {webhook_url, _enabled, _include_metadata, secret} =
      if button_id do
        get_effective_settings(user_id, button_id)
      else
        user_settings = get_user_settings(user_id)
        if user_settings do
          {user_settings.default_webhook_url, true, true, user_settings.webhook_secret}
        else
          {nil, false, true, nil}
        end
      end

    if webhook_url do
      test_payload = %{
        event: "test",
        timestamp: DateTime.to_iso8601(DateTime.utc_now()),
        message: "This is a test webhook from ButtonLog"
      }

      # Create a test delivery record
      {:ok, delivery} = create_delivery(
        %{
          channel: "webhook",
          destination: webhook_url,
          payload: test_payload,
          status: "pending"
        },
        user_id,
        button_id,
        nil
      )

      # Send synchronously for test so we can return the result
      case WebhookService.send_webhook(delivery, webhook_url, test_payload, secret: secret) do
        {:ok, delivery} -> {:ok, delivery}
        {:error, reason, delivery} -> {:error, reason, delivery}
      end
    else
      {:error, :no_webhook_configured}
    end
  end

  @doc """
  Retries a failed delivery.
  """
  def retry_delivery(delivery_id) do
    case get_delivery(delivery_id) do
      nil ->
        {:error, :not_found}

      delivery ->
        if delivery.status == "failed" do
          # Get user settings for secret
          user_settings = get_user_settings(delivery.user_id)
          secret = if user_settings, do: user_settings.webhook_secret, else: nil

          # Reset status to pending and retry
          delivery
          |> Ecto.Changeset.change(status: "pending")
          |> Repo.update!()

          WebhookService.send_webhook(delivery, delivery.destination, delivery.payload, secret: secret)
        else
          {:error, :not_failed}
        end
    end
  end

  # Private Functions

  defp get_effective_settings(user_id, button_id) do
    user_settings = get_user_settings(user_id)
    button_settings = get_button_settings(button_id)

    # Button settings override user settings when explicitly set
    webhook_url = get_setting(button_settings, :webhook_url) || get_setting(user_settings, :default_webhook_url)

    webhook_enabled =
      case get_setting(button_settings, :webhook_enabled) do
        nil -> get_setting(user_settings, :default_webhook_enabled) || false
        value -> value
      end

    include_metadata = get_setting(button_settings, :include_metadata) || true
    secret = get_setting(user_settings, :webhook_secret)

    {webhook_url, webhook_enabled, include_metadata, secret}
  end

  defp get_setting(nil, _field), do: nil
  defp get_setting(settings, field), do: Map.get(settings, field)
end

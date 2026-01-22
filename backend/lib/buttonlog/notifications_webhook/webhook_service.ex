defmodule ButtonLog.NotificationsWebhook.WebhookService do
  @moduledoc """
  Service for delivering webhook notifications to external HTTP endpoints.
  """

  require Logger
  alias ButtonLog.Repo
  alias ButtonLog.NotificationsWebhook.NotificationDelivery

  @doc """
  Sends a webhook notification to the specified URL.
  Returns {:ok, delivery} on success or {:error, reason} on failure.
  """
  def send_webhook(delivery, url, payload, options \\ []) do
    secret = Keyword.get(options, :secret)
    timeout = Keyword.get(options, :timeout, 10_000)

    headers = build_headers(payload, secret)
    body = Jason.encode!(payload)

    Logger.info("Sending webhook to #{url}")

    case :httpc.request(
           :post,
           {String.to_charlist(url), headers, ~c"application/json", body},
           [{:timeout, timeout}, {:connect_timeout, 5_000}],
           []
         ) do
      {:ok, {{_, status_code, _}, _headers, response_body}} when status_code in 200..299 ->
        response_body_str = to_string(response_body)
        Logger.info("Webhook delivered successfully: status=#{status_code}")

        delivery =
          delivery
          |> NotificationDelivery.mark_sent_changeset(status_code, response_body_str)
          |> Repo.update!()

        {:ok, delivery}

      {:ok, {{_, status_code, _}, _headers, response_body}} ->
        response_body_str = to_string(response_body)
        error_msg = "HTTP #{status_code}: #{String.slice(response_body_str, 0, 500)}"
        Logger.warning("Webhook failed: #{error_msg}")

        delivery =
          delivery
          |> NotificationDelivery.mark_failed_changeset(error_msg, status_code, response_body_str)
          |> Repo.update!()

        {:error, error_msg, delivery}

      {:error, reason} ->
        error_msg = "Request failed: #{inspect(reason)}"
        Logger.error("Webhook request failed: #{error_msg}")

        delivery =
          delivery
          |> NotificationDelivery.mark_failed_changeset(error_msg)
          |> Repo.update!()

        {:error, error_msg, delivery}
    end
  end

  @doc """
  Builds the standard webhook payload for a button click.
  """
  def build_button_click_payload(click, button, user, options \\ []) do
    include_metadata = Keyword.get(options, :include_metadata, true)

    payload = %{
      event: "button_click",
      timestamp: DateTime.to_iso8601(DateTime.utc_now()),
      button: %{
        id: button.id,
        name: button.name,
        type: button.type,
        current_state: button.current_state
      },
      click: %{
        id: click.id,
        action: click.action,
        clicked_at: DateTime.to_iso8601(click.clicked_at),
        platform: click.platform
      },
      user: %{
        id: user.id,
        display_name: user.display_name
      }
    }

    if include_metadata && click.metadata do
      put_in(payload, [:click, :metadata], click.metadata)
    else
      payload
    end
  end

  # Private functions

  defp build_headers(payload, secret) do
    base_headers = [
      {~c"Content-Type", ~c"application/json"},
      {~c"User-Agent", ~c"ButtonLog-Webhook/1.0"}
    ]

    if secret do
      signature = compute_signature(payload, secret)
      [{~c"X-ButtonLog-Signature", String.to_charlist(signature)} | base_headers]
    else
      base_headers
    end
  end

  defp compute_signature(payload, secret) do
    body = Jason.encode!(payload)
    :crypto.mac(:hmac, :sha256, secret, body) |> Base.encode16(case: :lower)
  end
end

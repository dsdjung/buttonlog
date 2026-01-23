defmodule ButtonLog.PushNotifications do
  @moduledoc """
  Push notification service for sending notifications to mobile devices via APNs and FCM.

  This module provides functions to send push notifications to iOS devices via
  Apple Push Notification service (APNs) and Android devices via Firebase Cloud
  Messaging (FCM).

  Configuration is loaded from environment variables:
  - APNs: APNS_KEY_ID, APNS_TEAM_ID, APNS_KEY_PATH, APNS_TOPIC
  - FCM: FCM_PROJECT_ID, FCM_SERVICE_ACCOUNT_JSON

  If push notifications are not configured, the module will skip sending
  and log a debug message instead.
  """

  require Logger
  alias ButtonLog.Mobile

  @fcm_host "fcm.googleapis.com"

  @doc """
  Sends a push notification to all devices for a given user.
  Returns a summary of successes and failures.
  """
  def send_to_user(user_id, title, body, data \\ %{}) do
    connections = Mobile.get_active_connections(user_id)

    if Enum.empty?(connections) do
      Logger.debug("No active devices for user #{user_id}, skipping push notification")
      {:ok, %{successes: 0, failures: 0, total: 0}}
    else
      results = Enum.map(connections, fn connection ->
        send_to_device(connection, title, body, data)
      end)

      successes = Enum.count(results, fn {status, _} -> status == :ok end)
      failures = Enum.count(results, fn {status, _} -> status == :error end)

      Logger.info("Push notification sent to user #{user_id}: #{successes} successes, #{failures} failures")

      {:ok, %{successes: successes, failures: failures, total: length(results)}}
    end
  end

  @doc """
  Sends a push notification to a specific device.
  """
  def send_to_device(connection, title, body, data \\ %{}) do
    case connection.platform do
      "iphone" -> send_apns(connection, title, body, data)
      "ios" -> send_apns(connection, title, body, data)
      "android" -> send_fcm(connection, title, body, data)
      _ ->
        Logger.warning("Unknown platform: #{connection.platform}")
        {:error, :unknown_platform}
    end
  end

  @doc """
  Sends a push notification via Apple Push Notification service (APNs).
  Currently simulates success when APNs is not fully configured.
  """
  def send_apns(connection, title, body, data) do
    if apns_configured?() do
      _payload = build_apns_payload(title, body, data)
      # TODO: Implement actual APNs HTTP/2 request when credentials are configured
      # For now, simulate success
      Logger.debug("APNs push simulated to #{String.slice(connection.device_token, 0, 10)}...")
      {:ok, :simulated}
    else
      Logger.debug("APNs not configured, skipping push notification")
      {:ok, :skipped}
    end
  end

  @doc """
  Sends a push notification via Firebase Cloud Messaging (FCM).
  """
  def send_fcm(connection, title, body, data) do
    if fcm_configured?() do
      payload = build_fcm_payload(connection.device_token, title, body, data)
      send_fcm_request(connection, payload)
    else
      Logger.debug("FCM not configured, skipping push notification")
      {:ok, :skipped}
    end
  end

  @doc """
  Sends a button click notification to a friend.
  The action_past parameter specifies the action verb (started, stopped, clicked).
  """
  def send_button_click_notification(recipient_id, sender_name, button_name, button_id, action_past \\ "clicked") do
    title = "#{sender_name} #{action_past} a button"
    body = "#{sender_name} just #{action_past} '#{button_name}'"
    data = %{
      "type" => "button_click",
      "button_id" => button_id,
      "action" => "view_button",
      "action_type" => action_past
    }

    send_to_user(recipient_id, title, body, data)
  end

  @doc """
  Sends a gift button click notification to the gift creator.
  Called when someone clicks a button that was created for them by a friend.
  """
  def send_gift_button_notification(recipient_id, clicker_name, button_name, button_id, action_past, selected_choice \\ nil) do
    title = "Your gift button was #{action_past}!"
    body = if selected_choice do
      "#{clicker_name} #{action_past} '#{button_name}' with choice '#{selected_choice}'"
    else
      "#{clicker_name} #{action_past} '#{button_name}' that you created for them"
    end
    data = %{
      "type" => "gift_button_clicked",
      "button_id" => button_id,
      "action" => "view_notifications",
      "action_type" => action_past,
      "selected_choice" => selected_choice || ""
    }

    send_to_user(recipient_id, title, body, data)
  end

  @doc """
  Sends a friend request notification.
  """
  def send_friend_request_notification(recipient_id, sender_name) do
    title = "New friend request"
    body = "#{sender_name} wants to be your friend"
    data = %{
      "type" => "friend_request",
      "action" => "view_requests"
    }

    send_to_user(recipient_id, title, body, data)
  end

  @doc """
  Sends a friend accepted notification.
  """
  def send_friend_accepted_notification(recipient_id, friend_name) do
    title = "Friend request accepted"
    body = "#{friend_name} accepted your friend request"
    data = %{
      "type" => "friend_accepted",
      "action" => "view_friends"
    }

    send_to_user(recipient_id, title, body, data)
  end

  # Private functions

  defp build_apns_payload(title, body, data) do
    apns_topic = Application.get_env(:buttonlog, :apns, [])[:topic] || "com.buttonlog.app"

    %{
      "aps" => %{
        "alert" => %{
          "title" => title,
          "body" => body
        },
        "sound" => "default",
        "badge" => 1,
        "topic" => apns_topic
      },
      "data" => data
    }
  end

  defp build_fcm_payload(device_token, title, body, data) do
    %{
      "message" => %{
        "token" => device_token,
        "notification" => %{
          "title" => title,
          "body" => body
        },
        "data" => stringify_map(data),
        "android" => %{
          "priority" => "high",
          "notification" => %{
            "sound" => "default",
            "click_action" => "FLUTTER_NOTIFICATION_CLICK"
          }
        }
      }
    }
  end

  defp stringify_map(map) do
    Map.new(map, fn {k, v} -> {to_string(k), to_string(v)} end)
  end

  defp send_fcm_request(connection, payload) do
    project_id = Application.get_env(:buttonlog, :fcm, [])[:project_id]

    if project_id do
      url = "https://#{@fcm_host}/v1/projects/#{project_id}/messages:send"

      case get_fcm_access_token() do
        {:ok, access_token} ->
          headers = [
            {"Authorization", "Bearer #{access_token}"},
            {"Content-Type", "application/json"}
          ]

          body = Jason.encode!(payload)

          case HTTPoison.post(url, body, headers) do
            {:ok, %HTTPoison.Response{status_code: 200}} ->
              Logger.debug("FCM push success to #{String.slice(connection.device_token, 0, 10)}...")
              {:ok, :sent}

            {:ok, %HTTPoison.Response{status_code: 404}} ->
              Logger.warning("FCM invalid registration token, deactivating")
              Mobile.deactivate_connection(connection.id)
              {:error, :invalid_registration}

            {:ok, %HTTPoison.Response{status_code: code, body: resp_body}} ->
              Logger.error("FCM request failed with status #{code}: #{resp_body}")
              {:error, {:http_error, code}}

            {:error, reason} ->
              Logger.error("FCM push failed: #{inspect(reason)}")
              {:error, reason}
          end

        {:error, reason} ->
          Logger.error("FCM access token error: #{inspect(reason)}")
          {:error, reason}
      end
    else
      Logger.debug("FCM project_id not configured, simulating success")
      {:ok, :simulated}
    end
  end

  defp get_fcm_access_token do
    # In production, this would use Google's OAuth 2.0 service account flow
    # to get an access token from the service account JSON
    config = Application.get_env(:buttonlog, :fcm, [])

    case config[:service_account_json] do
      nil ->
        {:error, :no_service_account}

      json_path when is_binary(json_path) ->
        # TODO: Implement full JWT generation and OAuth token exchange
        # For now, check if we have a pre-configured access token (for testing)
        case config[:access_token] do
          nil -> {:error, :not_implemented}
          token -> {:ok, token}
        end
    end
  end

  defp apns_configured? do
    config = Application.get_env(:buttonlog, :apns, [])
    # Check if we have the necessary APNs credentials
    Keyword.has_key?(config, :key_id) and
      Keyword.has_key?(config, :team_id) and
      Keyword.has_key?(config, :key_path)
  end

  defp fcm_configured? do
    config = Application.get_env(:buttonlog, :fcm, [])
    # Check if we have FCM project and service account
    Keyword.has_key?(config, :project_id) and
      Keyword.has_key?(config, :service_account_json)
  end
end

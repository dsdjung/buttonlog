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
  @apns_host_sandbox "api.sandbox.push.apple.com"
  @apns_host_production "api.push.apple.com"
  @apns_port 443

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
  Uses HTTP/2 via Finch to send notifications to iOS devices.
  """
  def send_apns(connection, title, body, data) do
    if apns_configured?() do
      payload = build_apns_payload(title, body, data)
      send_apns_request(connection, payload)
    else
      Logger.debug("APNs not configured, skipping push notification")
      {:ok, :skipped}
    end
  end

  defp send_apns_request(connection, payload) do
    config = Application.get_env(:buttonlog, :apns, [])
    environment = Keyword.get(config, :environment, :sandbox)
    topic = Keyword.get(config, :topic, "com.buttonlog.app")

    host = if environment == :production, do: @apns_host_production, else: @apns_host_sandbox
    url = "https://#{host}:#{@apns_port}/3/device/#{connection.device_token}"

    case get_apns_jwt() do
      {:ok, jwt} ->
        headers = [
          {"authorization", "bearer #{jwt}"},
          {"apns-topic", topic},
          {"apns-push-type", "alert"},
          {"apns-priority", "10"},
          {"apns-expiration", "0"},
          {"content-type", "application/json"}
        ]

        body = Jason.encode!(payload)

        request = Finch.build(:post, url, headers, body)

        case Finch.request(request, ButtonLog.Finch, receive_timeout: 30_000) do
          {:ok, %Finch.Response{status: 200}} ->
            Logger.debug("APNs push success to #{String.slice(connection.device_token, 0, 10)}...")
            {:ok, :sent}

          {:ok, %Finch.Response{status: 400, body: resp_body}} ->
            Logger.warning("APNs bad request: #{resp_body}")
            {:error, :bad_request}

          {:ok, %Finch.Response{status: 403, body: resp_body}} ->
            Logger.warning("APNs authentication error: #{resp_body}")
            {:error, :authentication_error}

          {:ok, %Finch.Response{status: 404, body: _resp_body}} ->
            Logger.warning("APNs invalid device token, deactivating connection")
            Mobile.deactivate_connection(connection.id)
            {:error, :invalid_token}

          {:ok, %Finch.Response{status: 410, body: _resp_body}} ->
            Logger.warning("APNs device token is no longer active, deactivating connection")
            Mobile.deactivate_connection(connection.id)
            {:error, :unregistered}

          {:ok, %Finch.Response{status: status, body: resp_body}} ->
            Logger.error("APNs request failed with status #{status}: #{resp_body}")
            {:error, {:http_error, status}}

          {:error, reason} ->
            Logger.error("APNs HTTP request failed: #{inspect(reason)}")
            {:error, reason}
        end

      {:error, reason} ->
        Logger.error("Failed to generate APNs JWT: #{inspect(reason)}")
        {:error, reason}
    end
  end

  defp get_apns_jwt do
    # Check cache first
    case :persistent_term.get({__MODULE__, :apns_token}, nil) do
      {token, expires_at} when is_binary(token) ->
        # APNs tokens are valid for 1 hour, refresh 5 minutes before expiry
        if DateTime.compare(DateTime.utc_now(), expires_at) == :lt do
          {:ok, token}
        else
          generate_new_apns_jwt()
        end

      _ ->
        generate_new_apns_jwt()
    end
  end

  defp generate_new_apns_jwt do
    config = Application.get_env(:buttonlog, :apns, [])
    key_id = Keyword.get(config, :key_id)
    team_id = Keyword.get(config, :team_id)
    key_path = Keyword.get(config, :key_path)

    with {:ok, private_key_pem} <- read_apns_key(key_path),
         {:ok, jwt} <- build_apns_jwt(key_id, team_id, private_key_pem) do
      # Cache for 50 minutes (tokens valid for 60 minutes)
      expires_at = DateTime.add(DateTime.utc_now(), 50 * 60, :second)
      :persistent_term.put({__MODULE__, :apns_token}, {jwt, expires_at})
      {:ok, jwt}
    end
  end

  defp read_apns_key(key_path) when is_binary(key_path) do
    # Support both file path and direct key content
    cond do
      String.starts_with?(key_path, "-----BEGIN") ->
        {:ok, key_path}

      File.exists?(key_path) ->
        File.read(key_path)

      true ->
        {:error, :key_not_found}
    end
  end

  defp read_apns_key(_), do: {:error, :invalid_key_path}

  defp build_apns_jwt(key_id, team_id, private_key_pem) do
    now = DateTime.utc_now() |> DateTime.to_unix()

    header = %{
      "alg" => "ES256",
      "typ" => "JWT",
      "kid" => key_id
    }

    claims = %{
      "iss" => team_id,
      "iat" => now
    }

    header_b64 = Base.url_encode64(Jason.encode!(header), padding: false)
    claims_b64 = Base.url_encode64(Jason.encode!(claims), padding: false)
    signing_input = "#{header_b64}.#{claims_b64}"

    case sign_with_es256(signing_input, private_key_pem) do
      {:ok, signature} ->
        signature_b64 = Base.url_encode64(signature, padding: false)
        {:ok, "#{signing_input}.#{signature_b64}"}

      error ->
        error
    end
  end

  defp sign_with_es256(data, pem_key) do
    try do
      [entry] = :public_key.pem_decode(pem_key)
      key = :public_key.pem_entry_decode(entry)
      # Sign with ECDSA SHA-256
      signature = :public_key.sign(data, :sha256, key)
      # Convert from DER format to raw R||S format (64 bytes)
      {:ok, der_to_raw_signature(signature)}
    rescue
      e ->
        Logger.error("ES256 signing failed: #{inspect(e)}")
        {:error, :signing_failed}
    end
  end

  # APNs requires the ECDSA signature in raw R||S format (64 bytes)
  # Erlang's :public_key.sign returns DER-encoded format
  defp der_to_raw_signature(der_signature) do
    # DER format: 0x30 <total_len> 0x02 <r_len> <r> 0x02 <s_len> <s>
    <<0x30, _total_len, 0x02, r_len, rest::binary>> = der_signature
    <<r::binary-size(r_len), 0x02, s_len, s::binary-size(s_len), _::binary>> = rest

    # Pad or trim R and S to exactly 32 bytes each
    r_padded = pad_or_trim(r, 32)
    s_padded = pad_or_trim(s, 32)

    r_padded <> s_padded
  end

  defp pad_or_trim(binary, target_size) do
    size = byte_size(binary)

    cond do
      size == target_size -> binary
      size > target_size -> binary_part(binary, size - target_size, target_size)
      size < target_size -> String.duplicate(<<0>>, target_size - size) <> binary
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
  The selected_choice parameter is for one-time buttons with multiple choice options.
  """
  def send_button_click_notification(recipient_id, sender_name, button_name, button_id, action_past \\ "clicked", selected_choice \\ nil) do
    {title, body} = if selected_choice do
      {
        "#{button_name}: #{selected_choice}",
        "#{sender_name} answered '#{selected_choice}' on '#{button_name}'"
      }
    else
      {
        "#{sender_name} #{action_past} a button",
        "#{sender_name} just #{action_past} '#{button_name}'"
      }
    end

    data = %{
      "type" => "button_click",
      "button_id" => button_id,
      "action" => "view_button",
      "action_type" => action_past,
      "selected_choice" => selected_choice
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

  @doc """
  Sends a button reminder notification.
  """
  def send_button_reminder_notification(user_id, button_name, button_id) do
    title = "Reminder: #{button_name}"
    body = "Time to click your button!"
    data = %{
      "type" => "button_reminder",
      "button_id" => button_id,
      "action" => "open_button"
    }

    send_to_user(user_id, title, body, data)
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
    # Use Google's OAuth 2.0 service account flow to get an access token
    config = Application.get_env(:buttonlog, :fcm, [])

    case config[:service_account_json] do
      nil ->
        {:error, :no_service_account}

      json_string when is_binary(json_string) ->
        # Check cache first
        case :persistent_term.get({__MODULE__, :fcm_token}, nil) do
          {token, expires_at} when is_binary(token) ->
            if DateTime.compare(DateTime.utc_now(), expires_at) == :lt do
              {:ok, token}
            else
              fetch_new_fcm_token(json_string)
            end

          _ ->
            fetch_new_fcm_token(json_string)
        end
    end
  end

  defp fetch_new_fcm_token(json_string) do
    with {:ok, service_account} <- Jason.decode(json_string),
         {:ok, jwt} <- build_google_jwt(service_account),
         {:ok, token, expires_in} <- exchange_jwt_for_token(jwt) do
      # Cache the token
      expires_at = DateTime.add(DateTime.utc_now(), expires_in - 60, :second)
      :persistent_term.put({__MODULE__, :fcm_token}, {token, expires_at})
      {:ok, token}
    end
  end

  defp build_google_jwt(service_account) do
    now = DateTime.utc_now() |> DateTime.to_unix()

    header = %{
      "alg" => "RS256",
      "typ" => "JWT"
    }

    claims = %{
      "iss" => service_account["client_email"],
      "scope" => "https://www.googleapis.com/auth/firebase.messaging",
      "aud" => "https://oauth2.googleapis.com/token",
      "iat" => now,
      "exp" => now + 3600
    }

    header_b64 = Base.url_encode64(Jason.encode!(header), padding: false)
    claims_b64 = Base.url_encode64(Jason.encode!(claims), padding: false)
    signing_input = "#{header_b64}.#{claims_b64}"

    private_key = service_account["private_key"]

    case sign_with_rsa(signing_input, private_key) do
      {:ok, signature} ->
        signature_b64 = Base.url_encode64(signature, padding: false)
        {:ok, "#{signing_input}.#{signature_b64}"}

      error ->
        error
    end
  end

  defp sign_with_rsa(data, pem_key) do
    try do
      [entry] = :public_key.pem_decode(pem_key)
      key = :public_key.pem_entry_decode(entry)
      signature = :public_key.sign(data, :sha256, key)
      {:ok, signature}
    rescue
      e ->
        Logger.error("RSA signing failed: #{inspect(e)}")
        {:error, :signing_failed}
    end
  end

  defp exchange_jwt_for_token(jwt) do
    url = "https://oauth2.googleapis.com/token"

    body = URI.encode_query(%{
      "grant_type" => "urn:ietf:params:oauth:grant-type:jwt-bearer",
      "assertion" => jwt
    })

    headers = [{"Content-Type", "application/x-www-form-urlencoded"}]

    case HTTPoison.post(url, body, headers) do
      {:ok, %HTTPoison.Response{status_code: 200, body: resp_body}} ->
        case Jason.decode(resp_body) do
          {:ok, %{"access_token" => token, "expires_in" => expires_in}} ->
            {:ok, token, expires_in}

          {:ok, resp} ->
            Logger.error("Unexpected OAuth response: #{inspect(resp)}")
            {:error, :unexpected_response}

          error ->
            error
        end

      {:ok, %HTTPoison.Response{status_code: code, body: resp_body}} ->
        Logger.error("OAuth token exchange failed (#{code}): #{resp_body}")
        {:error, {:oauth_failed, code}}

      {:error, reason} ->
        Logger.error("OAuth request failed: #{inspect(reason)}")
        {:error, reason}
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

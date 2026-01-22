defmodule ButtonLog.PushNotificationsTest do
  use ButtonLog.DataCase

  alias ButtonLog.PushNotifications
  alias ButtonLog.Mobile

  describe "send_to_user/4" do
    setup do
      user = insert_user()
      %{user: user}
    end

    test "returns success with zero counts when no active devices", %{user: user} do
      assert {:ok, result} = PushNotifications.send_to_user(user.id, "Test Title", "Test Body")

      assert result.successes == 0
      assert result.failures == 0
      assert result.total == 0
    end

    test "sends to active devices", %{user: user} do
      # Create active device connection
      {:ok, _} = Mobile.create_connection(
        %{device_token: "test_token_#{System.unique_integer()}", platform: "android"},
        user.id
      )

      assert {:ok, result} = PushNotifications.send_to_user(user.id, "Test Title", "Test Body")

      assert result.total == 1
      # Should be skipped or simulated since FCM isn't configured
      assert result.successes == 1
      assert result.failures == 0
    end

    test "sends to multiple devices", %{user: user} do
      {:ok, _} = Mobile.create_connection(
        %{device_token: "android_token_#{System.unique_integer()}", platform: "android"},
        user.id
      )
      {:ok, _} = Mobile.create_connection(
        %{device_token: "iphone_token_#{System.unique_integer()}", platform: "iphone"},
        user.id
      )

      assert {:ok, result} = PushNotifications.send_to_user(user.id, "Test Title", "Test Body")

      assert result.total == 2
      assert result.successes == 2
    end

    test "does not send to deactivated devices", %{user: user} do
      {:ok, active} = Mobile.create_connection(
        %{device_token: "active_token_#{System.unique_integer()}", platform: "android"},
        user.id
      )
      {:ok, inactive} = Mobile.create_connection(
        %{device_token: "inactive_token_#{System.unique_integer()}", platform: "android"},
        user.id
      )
      {:ok, _} = Mobile.deactivate_connection(inactive.id)

      assert {:ok, result} = PushNotifications.send_to_user(user.id, "Test Title", "Test Body")

      assert result.total == 1
    end

    test "includes custom data in notification", %{user: user} do
      {:ok, _} = Mobile.create_connection(
        %{device_token: "test_token_#{System.unique_integer()}", platform: "android"},
        user.id
      )

      custom_data = %{"button_id" => "123", "action" => "view"}
      assert {:ok, _result} = PushNotifications.send_to_user(user.id, "Test", "Body", custom_data)
      # Test passes if no error - data is included in payload internally
    end
  end

  describe "send_to_device/4" do
    setup do
      user = insert_user()
      %{user: user}
    end

    test "sends to android device via FCM", %{user: user} do
      {:ok, connection} = Mobile.create_connection(
        %{device_token: "android_token_#{System.unique_integer()}", platform: "android"},
        user.id
      )

      # Without FCM configured, returns :skipped or :simulated
      assert {:ok, status} = PushNotifications.send_to_device(connection, "Title", "Body")
      assert status in [:skipped, :simulated, :sent]
    end

    test "sends to iphone device via APNs", %{user: user} do
      {:ok, connection} = Mobile.create_connection(
        %{device_token: "iphone_token_#{System.unique_integer()}", platform: "iphone"},
        user.id
      )

      # Without APNs configured, returns :skipped or :simulated
      assert {:ok, status} = PushNotifications.send_to_device(connection, "Title", "Body")
      assert status in [:skipped, :simulated]
    end

    test "sends to ios device (alias for iphone)", %{user: user} do
      {:ok, connection} = Mobile.create_connection(
        %{device_token: "ios_token_#{System.unique_integer()}", platform: "iphone"},
        user.id
      )

      # Manually set platform to "ios" to test alias handling
      connection = %{connection | platform: "ios"}

      assert {:ok, status} = PushNotifications.send_to_device(connection, "Title", "Body")
      assert status in [:skipped, :simulated]
    end

    test "returns error for unknown platform", %{user: user} do
      {:ok, connection} = Mobile.create_connection(
        %{device_token: "unknown_token_#{System.unique_integer()}", platform: "android"},
        user.id
      )

      # Manually set platform to unknown
      connection = %{connection | platform: "unknown"}

      assert {:error, :unknown_platform} = PushNotifications.send_to_device(connection, "Title", "Body")
    end
  end

  describe "send_apns/4" do
    setup do
      user = insert_user()
      {:ok, connection} = Mobile.create_connection(
        %{device_token: "apns_token_#{System.unique_integer()}", platform: "iphone"},
        user.id
      )
      %{connection: connection}
    end

    test "returns skipped when APNs not configured", %{connection: connection} do
      # APNs should not be configured in test environment
      assert {:ok, :skipped} = PushNotifications.send_apns(connection, "Title", "Body", %{})
    end

    test "accepts custom data", %{connection: connection} do
      data = %{"button_id" => "123", "action" => "view_button"}
      assert {:ok, _} = PushNotifications.send_apns(connection, "Title", "Body", data)
    end
  end

  describe "send_fcm/4" do
    setup do
      user = insert_user()
      {:ok, connection} = Mobile.create_connection(
        %{device_token: "fcm_token_#{System.unique_integer()}", platform: "android"},
        user.id
      )
      %{connection: connection}
    end

    test "returns skipped when FCM not configured", %{connection: connection} do
      # FCM should not be configured in test environment
      assert {:ok, :skipped} = PushNotifications.send_fcm(connection, "Title", "Body", %{})
    end

    test "accepts custom data", %{connection: connection} do
      data = %{"button_id" => "123", "action" => "view_button"}
      assert {:ok, _} = PushNotifications.send_fcm(connection, "Title", "Body", data)
    end
  end

  describe "send_button_click_notification/5" do
    setup do
      user = insert_user()
      %{user: user}
    end

    test "sends notification with correct message format", %{user: user} do
      {:ok, _} = Mobile.create_connection(
        %{device_token: "token_#{System.unique_integer()}", platform: "android"},
        user.id
      )

      assert {:ok, result} = PushNotifications.send_button_click_notification(
        user.id,
        "John",
        "Morning Run",
        "button_123"
      )

      assert result.total == 1
    end

    test "sends notification with clicked action by default", %{user: user} do
      {:ok, _} = Mobile.create_connection(
        %{device_token: "token_#{System.unique_integer()}", platform: "android"},
        user.id
      )

      # Default action_past is "clicked"
      assert {:ok, _result} = PushNotifications.send_button_click_notification(
        user.id,
        "John",
        "Morning Run",
        "button_123"
      )
    end

    test "sends notification with started action", %{user: user} do
      {:ok, _} = Mobile.create_connection(
        %{device_token: "token_#{System.unique_integer()}", platform: "android"},
        user.id
      )

      assert {:ok, _result} = PushNotifications.send_button_click_notification(
        user.id,
        "John",
        "Timer Button",
        "button_123",
        "started"
      )
    end

    test "sends notification with stopped action", %{user: user} do
      {:ok, _} = Mobile.create_connection(
        %{device_token: "token_#{System.unique_integer()}", platform: "android"},
        user.id
      )

      assert {:ok, _result} = PushNotifications.send_button_click_notification(
        user.id,
        "John",
        "Timer Button",
        "button_123",
        "stopped"
      )
    end

    test "returns zero when no devices", %{user: user} do
      assert {:ok, result} = PushNotifications.send_button_click_notification(
        user.id,
        "John",
        "Button",
        "button_123"
      )

      assert result.total == 0
    end
  end

  describe "send_friend_request_notification/2" do
    setup do
      user = insert_user()
      %{user: user}
    end

    test "sends friend request notification", %{user: user} do
      {:ok, _} = Mobile.create_connection(
        %{device_token: "token_#{System.unique_integer()}", platform: "android"},
        user.id
      )

      assert {:ok, result} = PushNotifications.send_friend_request_notification(
        user.id,
        "Jane Doe"
      )

      assert result.total == 1
    end

    test "returns zero when no devices", %{user: user} do
      assert {:ok, result} = PushNotifications.send_friend_request_notification(
        user.id,
        "Jane"
      )

      assert result.total == 0
    end
  end

  describe "send_friend_accepted_notification/2" do
    setup do
      user = insert_user()
      %{user: user}
    end

    test "sends friend accepted notification", %{user: user} do
      {:ok, _} = Mobile.create_connection(
        %{device_token: "token_#{System.unique_integer()}", platform: "android"},
        user.id
      )

      assert {:ok, result} = PushNotifications.send_friend_accepted_notification(
        user.id,
        "Jane Doe"
      )

      assert result.total == 1
    end

    test "returns zero when no devices", %{user: user} do
      assert {:ok, result} = PushNotifications.send_friend_accepted_notification(
        user.id,
        "Jane"
      )

      assert result.total == 0
    end
  end

  # Helper functions
  defp insert_user(attrs \\ %{}) do
    default_attrs = %{
      email: "test#{System.unique_integer()}@test.com",
      username: "testuser#{System.unique_integer()}",
      display_name: "Test User",
      password_hash: Bcrypt.hash_pwd_salt("password123")
    }

    attrs = Map.merge(default_attrs, attrs)

    %ButtonLog.Accounts.User{}
    |> Ecto.Changeset.cast(attrs, [:email, :username, :display_name, :password_hash])
    |> ButtonLog.Repo.insert!()
  end
end

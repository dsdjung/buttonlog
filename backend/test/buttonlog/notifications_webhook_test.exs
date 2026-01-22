defmodule ButtonLog.NotificationsWebhookTest do
  use ButtonLog.DataCase

  alias ButtonLog.NotificationsWebhook

  describe "user notification settings" do
    test "get_user_settings/1 returns nil when no settings exist" do
      user = insert_user()
      assert NotificationsWebhook.get_user_settings(user.id) == nil
    end

    test "get_or_create_user_settings/1 creates settings if they don't exist" do
      user = insert_user()

      {:ok, settings} = NotificationsWebhook.get_or_create_user_settings(user.id)

      assert settings.user_id == user.id
      assert settings.default_webhook_enabled == false
      assert settings.default_webhook_url == nil
    end

    test "get_or_create_user_settings/1 returns existing settings" do
      user = insert_user()

      {:ok, settings1} = NotificationsWebhook.get_or_create_user_settings(user.id)
      {:ok, settings2} = NotificationsWebhook.get_or_create_user_settings(user.id)

      assert settings1.id == settings2.id
    end

    test "update_user_settings/2 creates settings if they don't exist" do
      user = insert_user()

      {:ok, settings} = NotificationsWebhook.update_user_settings(user.id, %{
        default_webhook_url: "https://example.com/webhook",
        default_webhook_enabled: true
      })

      assert settings.default_webhook_url == "https://example.com/webhook"
      assert settings.default_webhook_enabled == true
    end

    test "update_user_settings/2 updates existing settings" do
      user = insert_user()

      {:ok, _} = NotificationsWebhook.update_user_settings(user.id, %{
        default_webhook_url: "https://example.com/webhook",
        default_webhook_enabled: true
      })

      {:ok, updated} = NotificationsWebhook.update_user_settings(user.id, %{
        default_webhook_url: "https://new-url.com/webhook",
        default_webhook_enabled: false
      })

      assert updated.default_webhook_url == "https://new-url.com/webhook"
      assert updated.default_webhook_enabled == false
    end

    test "update_user_settings/2 validates webhook URL" do
      user = insert_user()

      {:error, changeset} = NotificationsWebhook.update_user_settings(user.id, %{
        default_webhook_url: "not-a-valid-url"
      })

      assert "must be a valid HTTP or HTTPS URL" in errors_on(changeset).default_webhook_url
    end

    test "update_user_settings/2 allows HTTPS URLs" do
      user = insert_user()

      {:ok, settings} = NotificationsWebhook.update_user_settings(user.id, %{
        default_webhook_url: "https://secure.example.com/webhook"
      })

      assert settings.default_webhook_url == "https://secure.example.com/webhook"
    end

    test "update_user_settings/2 allows HTTP URLs" do
      user = insert_user()

      {:ok, settings} = NotificationsWebhook.update_user_settings(user.id, %{
        default_webhook_url: "http://localhost:8080/webhook"
      })

      assert settings.default_webhook_url == "http://localhost:8080/webhook"
    end

    test "update_user_settings/2 stores webhook secret" do
      user = insert_user()

      {:ok, settings} = NotificationsWebhook.update_user_settings(user.id, %{
        webhook_secret: "my-secret-key-123"
      })

      assert settings.webhook_secret == "my-secret-key-123"
    end

    test "update_user_settings/2 validates max_retries range" do
      user = insert_user()

      {:error, changeset} = NotificationsWebhook.update_user_settings(user.id, %{
        max_retries: -1
      })

      assert "must be greater than or equal to 0" in errors_on(changeset).max_retries

      {:error, changeset} = NotificationsWebhook.update_user_settings(user.id, %{
        max_retries: 11
      })

      assert "must be less than or equal to 10" in errors_on(changeset).max_retries
    end
  end

  describe "button notification settings" do
    test "get_button_settings/1 returns nil when no settings exist" do
      user = insert_user()
      button = insert_button(user)

      assert NotificationsWebhook.get_button_settings(button.id) == nil
    end

    test "update_button_settings/2 creates settings if they don't exist" do
      user = insert_user()
      button = insert_button(user)

      {:ok, settings} = NotificationsWebhook.update_button_settings(button.id, %{
        webhook_url: "https://example.com/button-webhook",
        webhook_enabled: true
      })

      assert settings.button_id == button.id
      assert settings.webhook_url == "https://example.com/button-webhook"
      assert settings.webhook_enabled == true
    end

    test "update_button_settings/2 updates existing settings" do
      user = insert_user()
      button = insert_button(user)

      {:ok, _} = NotificationsWebhook.update_button_settings(button.id, %{
        webhook_enabled: true
      })

      {:ok, updated} = NotificationsWebhook.update_button_settings(button.id, %{
        webhook_enabled: false
      })

      assert updated.webhook_enabled == false
    end

    test "delete_button_settings/1 removes settings" do
      user = insert_user()
      button = insert_button(user)

      {:ok, _} = NotificationsWebhook.update_button_settings(button.id, %{
        webhook_enabled: true
      })

      {:ok, _} = NotificationsWebhook.delete_button_settings(button.id)

      assert NotificationsWebhook.get_button_settings(button.id) == nil
    end

    test "delete_button_settings/1 handles non-existent settings" do
      user = insert_user()
      button = insert_button(user)

      {:ok, nil} = NotificationsWebhook.delete_button_settings(button.id)
    end
  end

  describe "notification deliveries" do
    test "list_deliveries/1 returns empty list when no deliveries" do
      user = insert_user()

      deliveries = NotificationsWebhook.list_deliveries(user.id)

      assert deliveries == []
    end

    test "create_delivery/4 creates a delivery record" do
      user = insert_user()
      button = insert_button(user)

      {:ok, delivery} = NotificationsWebhook.create_delivery(
        %{
          channel: "webhook",
          destination: "https://example.com/webhook",
          payload: %{event: "test"},
          status: "pending"
        },
        user.id,
        button.id,
        nil
      )

      assert delivery.channel == "webhook"
      assert delivery.destination == "https://example.com/webhook"
      assert delivery.status == "pending"
      assert delivery.user_id == user.id
      assert delivery.button_id == button.id
    end

    test "list_deliveries/1 returns deliveries for a user" do
      user = insert_user()
      button = insert_button(user)

      {:ok, _delivery1} = NotificationsWebhook.create_delivery(
        %{channel: "webhook", destination: "https://a.com", payload: %{}, status: "sent"},
        user.id, button.id, nil
      )

      {:ok, _delivery2} = NotificationsWebhook.create_delivery(
        %{channel: "webhook", destination: "https://b.com", payload: %{}, status: "sent"},
        user.id, button.id, nil
      )

      deliveries = NotificationsWebhook.list_deliveries(user.id)

      assert length(deliveries) == 2
      # Verify all deliveries belong to the user
      assert Enum.all?(deliveries, fn d -> d.user_id == user.id end)
    end
  end

  describe "send_test_webhook/1" do
    test "returns error when no webhook configured" do
      user = insert_user()

      {:error, :no_webhook_configured} = NotificationsWebhook.send_test_webhook(user.id)
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

  defp insert_button(user, attrs \\ %{}) do
    default_attrs = %{
      name: "Test Button",
      type: "instant",
      color: "#3B82F6",
      icon: "star"
    }

    attrs = Map.merge(default_attrs, attrs)

    %ButtonLog.Buttons.Button{}
    |> Ecto.Changeset.cast(attrs, [:name, :type, :color, :icon])
    |> Ecto.Changeset.put_change(:user_id, user.id)
    |> ButtonLog.Repo.insert!()
  end
end

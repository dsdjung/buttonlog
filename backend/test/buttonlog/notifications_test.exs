defmodule ButtonLog.NotificationsTest do
  use ButtonLog.DataCase

  alias ButtonLog.Notifications
  alias ButtonLog.Notifications.{Notification, ButtonNotificationPreference, FriendNotificationPermission}
  alias ButtonLog.Buttons

  describe "notifications CRUD" do
    setup do
      sender = insert_user(%{email: "sender@example.com", username: "sender"})
      recipient = insert_user(%{email: "recipient@example.com", username: "recipient"})
      button = insert_button(sender, %{name: "Test Button"})
      %{sender: sender, recipient: recipient, button: button}
    end

    test "create_notification/4 creates a notification", %{sender: sender, recipient: recipient, button: button} do
      attrs = %{
        notification_type: "button_click",
        title: "Button Clicked",
        message: "Your friend clicked a button"
      }

      assert {:ok, %Notification{} = notification} =
        Notifications.create_notification(attrs, recipient.id, sender.id, button.id)

      assert notification.recipient_id == recipient.id
      assert notification.sender_id == sender.id
      assert notification.button_id == button.id
      assert notification.notification_type == "button_click"
      assert notification.read == false
    end

    test "get_user_notifications/1 returns notifications for user", %{sender: sender, recipient: recipient, button: button} do
      {:ok, _} = Notifications.create_notification(
        %{notification_type: "button_click", title: "Notification 1", message: "Test message 1"},
        recipient.id, sender.id, button.id
      )
      {:ok, _} = Notifications.create_notification(
        %{notification_type: "button_click", title: "Notification 2", message: "Test message 2"},
        recipient.id, sender.id, button.id
      )

      notifications = Notifications.get_user_notifications(recipient.id)
      assert length(notifications) == 2
    end

    test "get_user_notifications/1 returns empty list when no notifications", %{recipient: recipient} do
      notifications = Notifications.get_user_notifications(recipient.id)
      assert notifications == []
    end

    test "get_user_notifications_paginated/3 respects limit", %{sender: sender, recipient: recipient, button: button} do
      for i <- 1..5 do
        {:ok, _} = Notifications.create_notification(
          %{notification_type: "button_click", title: "Notification #{i}", message: "Test message #{i}"},
          recipient.id, sender.id, button.id
        )
      end

      {notifications, has_more} = Notifications.get_user_notifications_paginated(recipient.id, 3, 0)
      assert length(notifications) == 3
      assert has_more == true
    end

    test "get_user_notifications_paginated/3 returns has_more false when no more", %{sender: sender, recipient: recipient, button: button} do
      {:ok, _} = Notifications.create_notification(
        %{notification_type: "button_click", title: "Single Notification", message: "Test message"},
        recipient.id, sender.id, button.id
      )

      {notifications, has_more} = Notifications.get_user_notifications_paginated(recipient.id, 10, 0)
      assert length(notifications) == 1
      assert has_more == false
    end

    test "count_unread_notifications/1 counts unread notifications", %{sender: sender, recipient: recipient, button: button} do
      {:ok, _} = Notifications.create_notification(
        %{notification_type: "button_click", title: "Notification 1", message: "Test message 1"},
        recipient.id, sender.id, button.id
      )
      {:ok, notification2} = Notifications.create_notification(
        %{notification_type: "button_click", title: "Notification 2", message: "Test message 2"},
        recipient.id, sender.id, button.id
      )

      # Mark one as read
      {:ok, _} = Notifications.mark_notification_read(notification2.id, recipient.id)

      assert Notifications.count_unread_notifications(recipient.id) == 1
    end

    test "get_unread_notifications/1 returns only unread notifications", %{sender: sender, recipient: recipient, button: button} do
      {:ok, _} = Notifications.create_notification(
        %{notification_type: "button_click", title: "Unread", message: "Unread message"},
        recipient.id, sender.id, button.id
      )
      {:ok, notification2} = Notifications.create_notification(
        %{notification_type: "button_click", title: "Read", message: "Read message"},
        recipient.id, sender.id, button.id
      )

      # Mark one as read
      {:ok, _} = Notifications.mark_notification_read(notification2.id, recipient.id)

      unread = Notifications.get_unread_notifications(recipient.id)
      assert length(unread) == 1
      assert hd(unread).title == "Unread"
    end

    test "mark_notification_read/2 marks notification as read", %{sender: sender, recipient: recipient, button: button} do
      {:ok, notification} = Notifications.create_notification(
        %{notification_type: "button_click", title: "Test", message: "Test message"},
        recipient.id, sender.id, button.id
      )

      assert notification.read == false

      {:ok, updated} = Notifications.mark_notification_read(notification.id, recipient.id)
      assert updated.read == true
    end

    test "mark_notification_read/2 returns error for non-existent notification", %{recipient: recipient} do
      fake_id = Ecto.UUID.generate()
      assert {:error, :not_found} = Notifications.mark_notification_read(fake_id, recipient.id)
    end

    test "mark_notification_read/2 returns error for wrong user", %{sender: sender, recipient: recipient, button: button} do
      {:ok, notification} = Notifications.create_notification(
        %{notification_type: "button_click", title: "Test", message: "Test message"},
        recipient.id, sender.id, button.id
      )

      # Sender tries to mark recipient's notification as read
      assert {:error, :not_found} = Notifications.mark_notification_read(notification.id, sender.id)
    end

    test "mark_all_notifications_read/1 marks all as read", %{sender: sender, recipient: recipient, button: button} do
      {:ok, _} = Notifications.create_notification(
        %{notification_type: "button_click", title: "Notification 1", message: "Test message 1"},
        recipient.id, sender.id, button.id
      )
      {:ok, _} = Notifications.create_notification(
        %{notification_type: "button_click", title: "Notification 2", message: "Test message 2"},
        recipient.id, sender.id, button.id
      )

      assert Notifications.count_unread_notifications(recipient.id) == 2

      {:ok, count} = Notifications.mark_all_notifications_read(recipient.id)
      assert count == 2

      assert Notifications.count_unread_notifications(recipient.id) == 0
    end

    test "get_notifications_from_friend/2 returns notifications from specific friend", %{sender: sender, recipient: recipient, button: button} do
      other_sender = insert_user(%{email: "other@example.com", username: "other"})

      # Notification from sender
      {:ok, _} = Notifications.create_notification(
        %{notification_type: "button_click", title: "From Sender", message: "From sender message"},
        recipient.id, sender.id, button.id
      )

      # Notification from other sender
      other_button = insert_button(other_sender, %{name: "Other Button"})
      {:ok, _} = Notifications.create_notification(
        %{notification_type: "button_click", title: "From Other", message: "From other message"},
        recipient.id, other_sender.id, other_button.id
      )

      notifications = Notifications.get_notifications_from_friend(recipient.id, sender.id)
      assert length(notifications) == 1
      assert hd(notifications).title == "From Sender"
    end
  end

  describe "button notification preferences" do
    setup do
      user = insert_user(%{email: "user@example.com", username: "user"})
      friend = insert_user(%{email: "friend@example.com", username: "friend"})
      button = insert_button(user, %{name: "Test Button"})
      %{user: user, friend: friend, button: button}
    end

    test "get_button_notification_settings/1 returns empty list when no settings", %{button: button} do
      assert Notifications.get_button_notification_settings(button.id) == []
    end

    test "set_button_friend_notification/5 creates notification preference", %{user: user, friend: friend, button: button} do
      assert {:ok, %ButtonNotificationPreference{} = pref} =
        Notifications.set_button_friend_notification(button.id, user.id, friend.id, true)

      assert pref.button_id == button.id
      assert pref.user_id == user.id
      assert pref.friend_id == friend.id
      assert pref.enabled == true
    end

    test "set_button_friend_notification/5 updates existing preference", %{user: user, friend: friend, button: button} do
      {:ok, _} = Notifications.set_button_friend_notification(button.id, user.id, friend.id, true)
      {:ok, updated} = Notifications.set_button_friend_notification(button.id, user.id, friend.id, false)

      assert updated.enabled == false
    end

    test "toggle_button_friend_notification/3 toggles preference", %{user: user, friend: friend, button: button} do
      # First toggle creates with enabled = true
      {:ok, pref1} = Notifications.toggle_button_friend_notification(button.id, user.id, friend.id)
      assert pref1.enabled == true

      # Second toggle sets to false
      {:ok, pref2} = Notifications.toggle_button_friend_notification(button.id, user.id, friend.id)
      assert pref2.enabled == false

      # Third toggle sets back to true
      {:ok, pref3} = Notifications.toggle_button_friend_notification(button.id, user.id, friend.id)
      assert pref3.enabled == true
    end

    test "get_notification_recipients/2 returns enabled recipients", %{user: user, button: button} do
      friend1 = insert_user(%{email: "friend1@example.com", username: "friend1"})
      friend2 = insert_user(%{email: "friend2@example.com", username: "friend2"})
      friend3 = insert_user(%{email: "friend3@example.com", username: "friend3"})

      # Enable for friend1 and friend2, disable for friend3
      {:ok, _} = Notifications.set_button_friend_notification(button.id, user.id, friend1.id, true)
      {:ok, _} = Notifications.set_button_friend_notification(button.id, user.id, friend2.id, true)
      {:ok, _} = Notifications.set_button_friend_notification(button.id, user.id, friend3.id, false)

      recipients = Notifications.get_notification_recipients(button.id, user.id)
      recipient_ids = Enum.map(recipients, & &1.id)

      assert length(recipients) == 2
      assert friend1.id in recipient_ids
      assert friend2.id in recipient_ids
      refute friend3.id in recipient_ids
    end

    test "get_button_notification_preferences/2 returns preferences for button and user", %{user: user, button: button} do
      friend1 = insert_user(%{email: "friend1@example.com", username: "friend1"})
      friend2 = insert_user(%{email: "friend2@example.com", username: "friend2"})

      {:ok, _} = Notifications.set_button_friend_notification(button.id, user.id, friend1.id, true)
      {:ok, _} = Notifications.set_button_friend_notification(button.id, user.id, friend2.id, false)

      prefs = Notifications.get_button_notification_preferences(button.id, user.id)
      assert length(prefs) == 2
    end
  end

  describe "friend notification permissions" do
    setup do
      user = insert_user(%{email: "user@example.com", username: "user"})
      friend = insert_user(%{email: "friend@example.com", username: "friend"})
      %{user: user, friend: friend}
    end

    test "get_friend_notification_permissions/2 returns nil when no permissions set", %{user: user, friend: friend} do
      assert Notifications.get_friend_notification_permissions(user.id, friend.id) == nil
    end

    test "upsert_friend_notification_permissions/3 creates new permissions", %{user: user, friend: friend} do
      attrs = %{
        can_receive_button_notifications: true,
        can_receive_friend_requests: true,
        notification_frequency: "immediate"
      }

      assert {:ok, %FriendNotificationPermission{} = perm} =
        Notifications.upsert_friend_notification_permissions(attrs, user.id, friend.id)

      assert perm.user_id == user.id
      assert perm.friend_id == friend.id
      assert perm.can_receive_button_notifications == true
      assert perm.notification_frequency == "immediate"
    end

    test "upsert_friend_notification_permissions/3 updates existing permissions", %{user: user, friend: friend} do
      attrs1 = %{
        can_receive_button_notifications: true,
        notification_frequency: "immediate"
      }
      {:ok, _} = Notifications.upsert_friend_notification_permissions(attrs1, user.id, friend.id)

      attrs2 = %{
        can_receive_button_notifications: false,
        notification_frequency: "daily"
      }
      {:ok, updated} = Notifications.upsert_friend_notification_permissions(attrs2, user.id, friend.id)

      assert updated.can_receive_button_notifications == false
      assert updated.notification_frequency == "daily"
    end
  end

  describe "get_action_verbs/1" do
    # Note: get_action_verbs is a private function, so we test it indirectly
    # through the notification message content

    test "notification messages use 'started' for start action" do
      # Create test user, friend, and button
      user = insert_user()
      friend = insert_user(%{email: "friend@test.com", username: "friend"})
      button = insert_button(user, %{name: "Test Timer", button_type: "toggle"})

      # Set up notification preference so friend receives notifications
      Notifications.set_button_friend_notification(button.id, user.id, friend.id, true)

      # Send notification with start action
      {:ok, _results} = Notifications.send_button_click_notifications(
        button.id,
        user.id,
        %{action: "start", clicked_at: DateTime.utc_now()}
      )

      # Get the notification
      notifications = Notifications.get_user_notifications(friend.id)
      assert length(notifications) == 1

      notification = hd(notifications)
      assert notification.title =~ "started"
      assert notification.message =~ "started"
      refute notification.title =~ "clicked"
    end

    test "notification messages use 'stopped' for stop action" do
      user = insert_user()
      friend = insert_user(%{email: "friend2@test.com", username: "friend2"})
      button = insert_button(user, %{name: "Test Timer", button_type: "toggle"})

      Notifications.set_button_friend_notification(button.id, user.id, friend.id, true)

      {:ok, _results} = Notifications.send_button_click_notifications(
        button.id,
        user.id,
        %{action: "stop", clicked_at: DateTime.utc_now()}
      )

      notifications = Notifications.get_user_notifications(friend.id)
      assert length(notifications) == 1

      notification = hd(notifications)
      assert notification.title =~ "stopped"
      assert notification.message =~ "stopped"
      refute notification.title =~ "clicked"
    end

    test "notification messages use 'stopped' for end action (toggle button stop)" do
      user = insert_user()
      friend = insert_user(%{email: "friend2b@test.com", username: "friend2b"})
      button = insert_button(user, %{name: "Test Timer", button_type: "toggle"})

      Notifications.set_button_friend_notification(button.id, user.id, friend.id, true)

      # The buttons context uses "end" action when stopping a toggle button
      {:ok, _results} = Notifications.send_button_click_notifications(
        button.id,
        user.id,
        %{action: "end", clicked_at: DateTime.utc_now()}
      )

      notifications = Notifications.get_user_notifications(friend.id)
      assert length(notifications) == 1

      notification = hd(notifications)
      assert notification.title =~ "stopped"
      assert notification.message =~ "stopped"
      refute notification.title =~ "clicked"
    end

    test "notification messages use 'clicked' for click action (instant buttons)" do
      user = insert_user()
      friend = insert_user(%{email: "friend3@test.com", username: "friend3"})
      button = insert_button(user, %{name: "Test Button", button_type: "instant"})

      Notifications.set_button_friend_notification(button.id, user.id, friend.id, true)

      {:ok, _results} = Notifications.send_button_click_notifications(
        button.id,
        user.id,
        %{action: "click", clicked_at: DateTime.utc_now()}
      )

      notifications = Notifications.get_user_notifications(friend.id)
      assert length(notifications) == 1

      notification = hd(notifications)
      assert notification.title =~ "clicked"
      assert notification.message =~ "clicked"
    end

    test "notification messages default to 'clicked' when no action specified" do
      user = insert_user()
      friend = insert_user(%{email: "friend4@test.com", username: "friend4"})
      button = insert_button(user, %{name: "Test Button", button_type: "instant"})

      Notifications.set_button_friend_notification(button.id, user.id, friend.id, true)

      {:ok, _results} = Notifications.send_button_click_notifications(
        button.id,
        user.id,
        %{}  # No action specified
      )

      notifications = Notifications.get_user_notifications(friend.id)
      assert length(notifications) == 1

      notification = hd(notifications)
      assert notification.title =~ "clicked"
      assert notification.message =~ "clicked"
    end

    test "handles string action keys" do
      user = insert_user()
      friend = insert_user(%{email: "friend5@test.com", username: "friend5"})
      button = insert_button(user, %{name: "Test Timer", button_type: "toggle"})

      Notifications.set_button_friend_notification(button.id, user.id, friend.id, true)

      # Use string key instead of atom
      {:ok, _results} = Notifications.send_button_click_notifications(
        button.id,
        user.id,
        %{"action" => "start", "clicked_at" => DateTime.utc_now()}
      )

      notifications = Notifications.get_user_notifications(friend.id)
      assert length(notifications) == 1

      notification = hd(notifications)
      assert notification.title =~ "started"
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

  defp insert_button(user, attrs) do
    # Convert button_type to type if present
    attrs = if Map.has_key?(attrs, :button_type) do
      attrs
      |> Map.put(:type, attrs.button_type)
      |> Map.delete(:button_type)
    else
      attrs
    end

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

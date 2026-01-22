defmodule ButtonLog.AlertsTest do
  use ButtonLog.DataCase

  alias ButtonLog.Alerts
  alias ButtonLog.Alerts.{Alert, ButtonAlertPreference, FriendAlertPermission}

  describe "alerts CRUD" do
    setup do
      sender = insert_user(%{email: "sender@example.com", username: "sender"})
      recipient = insert_user(%{email: "recipient@example.com", username: "recipient"})
      button = insert_button(sender, %{name: "Test Button"})
      %{sender: sender, recipient: recipient, button: button}
    end

    test "create_alert/4 creates an alert", %{sender: sender, recipient: recipient, button: button} do
      attrs = %{
        alert_type: "button_click",
        title: "Button Clicked",
        message: "Your friend clicked a button"
      }

      assert {:ok, %Alert{} = alert} =
        Alerts.create_alert(attrs, recipient.id, sender.id, button.id)

      assert alert.recipient_id == recipient.id
      assert alert.sender_id == sender.id
      assert alert.button_id == button.id
      assert alert.alert_type == "button_click"
      assert alert.read == false
    end

    test "create_alert/4 with all valid alert types", %{sender: sender, recipient: recipient, button: button} do
      valid_types = [
        "button_click", "button_created", "friend_request", "general",
        "gift_button_received", "gift_button_clicked", "gift_button_deleted", "gift_button_sent",
        "one_time_button_completed",
        "support_ticket_reply", "support_ticket_status_update"
      ]

      for alert_type <- valid_types do
        attrs = %{
          alert_type: alert_type,
          title: "Test #{alert_type}",
          message: "Test message for #{alert_type}"
        }

        assert {:ok, %Alert{} = alert} =
          Alerts.create_alert(attrs, recipient.id, sender.id, button.id)

        assert alert.alert_type == alert_type
      end
    end

    test "create_alert/4 fails with invalid alert type", %{sender: sender, recipient: recipient, button: button} do
      attrs = %{
        alert_type: "invalid_type",
        title: "Test",
        message: "Test message"
      }

      assert {:error, changeset} =
        Alerts.create_alert(attrs, recipient.id, sender.id, button.id)

      assert "is invalid" in errors_on(changeset).alert_type
    end

    test "create_alert/4 with metadata", %{sender: sender, recipient: recipient, button: button} do
      attrs = %{
        alert_type: "button_click",
        title: "Button Clicked",
        message: "Your friend clicked a button",
        metadata: %{"action" => "start", "duration" => 120}
      }

      assert {:ok, %Alert{} = alert} =
        Alerts.create_alert(attrs, recipient.id, sender.id, button.id)

      assert alert.metadata == %{"action" => "start", "duration" => 120}
    end

    test "create_alert/4 with clicked_at timestamp", %{sender: sender, recipient: recipient, button: button} do
      clicked_at = DateTime.utc_now() |> DateTime.truncate(:second)
      attrs = %{
        alert_type: "button_click",
        title: "Button Clicked",
        message: "Your friend clicked a button",
        clicked_at: clicked_at
      }

      assert {:ok, %Alert{} = alert} =
        Alerts.create_alert(attrs, recipient.id, sender.id, button.id)

      assert alert.clicked_at == clicked_at
    end

    test "get_user_alerts/1 returns alerts for user", %{sender: sender, recipient: recipient, button: button} do
      {:ok, _} = Alerts.create_alert(
        %{alert_type: "button_click", title: "Alert 1", message: "Test message 1"},
        recipient.id, sender.id, button.id
      )
      {:ok, _} = Alerts.create_alert(
        %{alert_type: "button_click", title: "Alert 2", message: "Test message 2"},
        recipient.id, sender.id, button.id
      )

      alerts = Alerts.get_user_alerts(recipient.id)
      assert length(alerts) == 2
    end

    test "get_user_alerts/1 returns empty list when no alerts", %{recipient: recipient} do
      alerts = Alerts.get_user_alerts(recipient.id)
      assert alerts == []
    end

    test "get_user_alerts/2 respects limit parameter", %{sender: sender, recipient: recipient, button: button} do
      for i <- 1..10 do
        {:ok, _} = Alerts.create_alert(
          %{alert_type: "button_click", title: "Alert #{i}", message: "Test message #{i}"},
          recipient.id, sender.id, button.id
        )
      end

      alerts = Alerts.get_user_alerts(recipient.id, 5)
      assert length(alerts) == 5
    end

    test "get_user_alerts/1 orders by inserted_at desc", %{sender: sender, recipient: recipient, button: button} do
      {:ok, alert1} = Alerts.create_alert(
        %{alert_type: "button_click", title: "First", message: "First alert"},
        recipient.id, sender.id, button.id
      )
      # Use 1 second sleep to ensure different timestamps in the database
      :timer.sleep(1000)
      {:ok, alert2} = Alerts.create_alert(
        %{alert_type: "button_click", title: "Second", message: "Second alert"},
        recipient.id, sender.id, button.id
      )

      alerts = Alerts.get_user_alerts(recipient.id)
      # The most recent (alert2) should be first
      assert hd(alerts).id == alert2.id
      assert List.last(alerts).id == alert1.id
    end

    test "get_user_alerts_paginated/3 respects limit", %{sender: sender, recipient: recipient, button: button} do
      for i <- 1..5 do
        {:ok, _} = Alerts.create_alert(
          %{alert_type: "button_click", title: "Alert #{i}", message: "Test message #{i}"},
          recipient.id, sender.id, button.id
        )
      end

      {alerts, has_more} = Alerts.get_user_alerts_paginated(recipient.id, 3, 0)
      assert length(alerts) == 3
      assert has_more == true
    end

    test "get_user_alerts_paginated/3 returns has_more false when no more", %{sender: sender, recipient: recipient, button: button} do
      {:ok, _} = Alerts.create_alert(
        %{alert_type: "button_click", title: "Single Alert", message: "Test message"},
        recipient.id, sender.id, button.id
      )

      {alerts, has_more} = Alerts.get_user_alerts_paginated(recipient.id, 10, 0)
      assert length(alerts) == 1
      assert has_more == false
    end

    test "get_user_alerts_paginated/3 respects offset", %{sender: sender, recipient: recipient, button: button} do
      for i <- 1..5 do
        {:ok, _} = Alerts.create_alert(
          %{alert_type: "button_click", title: "Alert #{i}", message: "Test message #{i}"},
          recipient.id, sender.id, button.id
        )
      end

      {alerts, _has_more} = Alerts.get_user_alerts_paginated(recipient.id, 2, 2)
      assert length(alerts) == 2
    end

    test "count_unread_alerts/1 counts unread alerts", %{sender: sender, recipient: recipient, button: button} do
      {:ok, _} = Alerts.create_alert(
        %{alert_type: "button_click", title: "Alert 1", message: "Test message 1"},
        recipient.id, sender.id, button.id
      )
      {:ok, alert2} = Alerts.create_alert(
        %{alert_type: "button_click", title: "Alert 2", message: "Test message 2"},
        recipient.id, sender.id, button.id
      )

      # Mark one as read
      {:ok, _} = Alerts.mark_alert_read(alert2.id, recipient.id)

      assert Alerts.count_unread_alerts(recipient.id) == 1
    end

    test "count_unread_alerts/1 returns 0 when all read", %{sender: sender, recipient: recipient, button: button} do
      {:ok, alert} = Alerts.create_alert(
        %{alert_type: "button_click", title: "Alert", message: "Test message"},
        recipient.id, sender.id, button.id
      )
      {:ok, _} = Alerts.mark_alert_read(alert.id, recipient.id)

      assert Alerts.count_unread_alerts(recipient.id) == 0
    end

    test "get_unread_alerts/1 returns only unread alerts", %{sender: sender, recipient: recipient, button: button} do
      {:ok, _} = Alerts.create_alert(
        %{alert_type: "button_click", title: "Unread", message: "Unread message"},
        recipient.id, sender.id, button.id
      )
      {:ok, alert2} = Alerts.create_alert(
        %{alert_type: "button_click", title: "Read", message: "Read message"},
        recipient.id, sender.id, button.id
      )

      # Mark one as read
      {:ok, _} = Alerts.mark_alert_read(alert2.id, recipient.id)

      unread = Alerts.get_unread_alerts(recipient.id)
      assert length(unread) == 1
      assert hd(unread).title == "Unread"
    end

    test "mark_alert_read/2 marks alert as read", %{sender: sender, recipient: recipient, button: button} do
      {:ok, alert} = Alerts.create_alert(
        %{alert_type: "button_click", title: "Test", message: "Test message"},
        recipient.id, sender.id, button.id
      )

      assert alert.read == false

      {:ok, updated} = Alerts.mark_alert_read(alert.id, recipient.id)
      assert updated.read == true
    end

    test "mark_alert_read/2 returns error for non-existent alert", %{recipient: recipient} do
      fake_id = Ecto.UUID.generate()
      assert {:error, :not_found} = Alerts.mark_alert_read(fake_id, recipient.id)
    end

    test "mark_alert_read/2 returns error for wrong user", %{sender: sender, recipient: recipient, button: button} do
      {:ok, alert} = Alerts.create_alert(
        %{alert_type: "button_click", title: "Test", message: "Test message"},
        recipient.id, sender.id, button.id
      )

      # Sender tries to mark recipient's alert as read
      assert {:error, :not_found} = Alerts.mark_alert_read(alert.id, sender.id)
    end

    test "mark_all_alerts_read/1 marks all as read", %{sender: sender, recipient: recipient, button: button} do
      {:ok, _} = Alerts.create_alert(
        %{alert_type: "button_click", title: "Alert 1", message: "Test message 1"},
        recipient.id, sender.id, button.id
      )
      {:ok, _} = Alerts.create_alert(
        %{alert_type: "button_click", title: "Alert 2", message: "Test message 2"},
        recipient.id, sender.id, button.id
      )

      assert Alerts.count_unread_alerts(recipient.id) == 2

      {:ok, count} = Alerts.mark_all_alerts_read(recipient.id)
      assert count == 2

      assert Alerts.count_unread_alerts(recipient.id) == 0
    end

    test "mark_all_alerts_read/1 returns 0 when no unread alerts", %{recipient: recipient} do
      {:ok, count} = Alerts.mark_all_alerts_read(recipient.id)
      assert count == 0
    end

    test "get_alerts_from_friend/2 returns alerts from specific friend", %{sender: sender, recipient: recipient, button: button} do
      other_sender = insert_user(%{email: "other@example.com", username: "other"})

      # Alert from sender
      {:ok, _} = Alerts.create_alert(
        %{alert_type: "button_click", title: "From Sender", message: "From sender message"},
        recipient.id, sender.id, button.id
      )

      # Alert from other sender
      other_button = insert_button(other_sender, %{name: "Other Button"})
      {:ok, _} = Alerts.create_alert(
        %{alert_type: "button_click", title: "From Other", message: "From other message"},
        recipient.id, other_sender.id, other_button.id
      )

      alerts = Alerts.get_alerts_from_friend(recipient.id, sender.id)
      assert length(alerts) == 1
      assert hd(alerts).title == "From Sender"
    end

    test "get_alerts_from_friend/3 respects limit parameter", %{sender: sender, recipient: recipient, button: button} do
      for i <- 1..5 do
        {:ok, _} = Alerts.create_alert(
          %{alert_type: "button_click", title: "Alert #{i}", message: "Test message #{i}"},
          recipient.id, sender.id, button.id
        )
      end

      alerts = Alerts.get_alerts_from_friend(recipient.id, sender.id, 2)
      assert length(alerts) == 2
    end

    test "get_alert!/1 returns alert by id", %{sender: sender, recipient: recipient, button: button} do
      {:ok, alert} = Alerts.create_alert(
        %{alert_type: "button_click", title: "Test", message: "Test message"},
        recipient.id, sender.id, button.id
      )

      fetched = Alerts.get_alert!(alert.id)
      assert fetched.id == alert.id
      assert fetched.title == "Test"
    end

    test "get_alert!/1 raises for non-existent alert" do
      fake_id = Ecto.UUID.generate()
      assert_raise Ecto.NoResultsError, fn ->
        Alerts.get_alert!(fake_id)
      end
    end

    test "change_alert/2 returns a changeset", %{sender: sender, recipient: recipient, button: button} do
      {:ok, alert} = Alerts.create_alert(
        %{alert_type: "button_click", title: "Test", message: "Test message"},
        recipient.id, sender.id, button.id
      )

      changeset = Alerts.change_alert(alert, %{title: "New Title"})
      assert %Ecto.Changeset{} = changeset
    end
  end

  describe "button alert preferences" do
    setup do
      user = insert_user(%{email: "user@example.com", username: "user"})
      friend = insert_user(%{email: "friend@example.com", username: "friend"})
      button = insert_button(user, %{name: "Test Button"})
      %{user: user, friend: friend, button: button}
    end

    test "get_button_alert_settings/1 returns empty list when no settings", %{button: button} do
      assert Alerts.get_button_alert_settings(button.id) == []
    end

    test "get_button_alert_settings/1 returns all settings for button", %{user: user, button: button} do
      friend1 = insert_user(%{email: "friend1@example.com", username: "friend1"})
      friend2 = insert_user(%{email: "friend2@example.com", username: "friend2"})

      {:ok, _} = Alerts.set_button_friend_alert(button.id, user.id, friend1.id, true)
      {:ok, _} = Alerts.set_button_friend_alert(button.id, user.id, friend2.id, false)

      settings = Alerts.get_button_alert_settings(button.id)
      assert length(settings) == 2
    end

    test "set_button_friend_alert/5 creates alert preference", %{user: user, friend: friend, button: button} do
      assert {:ok, %ButtonAlertPreference{} = pref} =
        Alerts.set_button_friend_alert(button.id, user.id, friend.id, true)

      assert pref.button_id == button.id
      assert pref.user_id == user.id
      assert pref.friend_id == friend.id
      assert pref.enabled == true
      assert pref.alert_type == "click"
    end

    test "set_button_friend_alert/5 creates with custom alert type", %{user: user, friend: friend, button: button} do
      assert {:ok, %ButtonAlertPreference{} = pref} =
        Alerts.set_button_friend_alert(button.id, user.id, friend.id, true, "start")

      assert pref.alert_type == "start"
    end

    test "set_button_friend_alert/5 validates alert type", %{user: user, friend: friend, button: button} do
      assert {:error, changeset} =
        Alerts.set_button_friend_alert(button.id, user.id, friend.id, true, "invalid")

      assert "is invalid" in errors_on(changeset).alert_type
    end

    test "set_button_friend_alert/5 updates existing preference", %{user: user, friend: friend, button: button} do
      {:ok, _} = Alerts.set_button_friend_alert(button.id, user.id, friend.id, true)
      {:ok, updated} = Alerts.set_button_friend_alert(button.id, user.id, friend.id, false)

      assert updated.enabled == false
    end

    test "set_button_friend_alert/5 updates alert type", %{user: user, friend: friend, button: button} do
      {:ok, _} = Alerts.set_button_friend_alert(button.id, user.id, friend.id, true, "click")
      {:ok, updated} = Alerts.set_button_friend_alert(button.id, user.id, friend.id, true, "all")

      assert updated.alert_type == "all"
    end

    test "toggle_button_friend_alert/3 toggles preference", %{user: user, friend: friend, button: button} do
      # First toggle creates with enabled = true
      {:ok, pref1} = Alerts.toggle_button_friend_alert(button.id, user.id, friend.id)
      assert pref1.enabled == true

      # Second toggle sets to false
      {:ok, pref2} = Alerts.toggle_button_friend_alert(button.id, user.id, friend.id)
      assert pref2.enabled == false

      # Third toggle sets back to true
      {:ok, pref3} = Alerts.toggle_button_friend_alert(button.id, user.id, friend.id)
      assert pref3.enabled == true
    end

    test "get_alert_recipients/2 returns enabled recipients", %{user: user, button: button} do
      friend1 = insert_user(%{email: "friend1@example.com", username: "friend1"})
      friend2 = insert_user(%{email: "friend2@example.com", username: "friend2"})
      friend3 = insert_user(%{email: "friend3@example.com", username: "friend3"})

      # Enable for friend1 and friend2, disable for friend3
      {:ok, _} = Alerts.set_button_friend_alert(button.id, user.id, friend1.id, true)
      {:ok, _} = Alerts.set_button_friend_alert(button.id, user.id, friend2.id, true)
      {:ok, _} = Alerts.set_button_friend_alert(button.id, user.id, friend3.id, false)

      recipients = Alerts.get_alert_recipients(button.id, user.id)
      recipient_ids = Enum.map(recipients, & &1.id)

      assert length(recipients) == 2
      assert friend1.id in recipient_ids
      assert friend2.id in recipient_ids
      refute friend3.id in recipient_ids
    end

    test "get_alert_recipients/2 returns empty list when no enabled preferences", %{user: user, button: button} do
      friend = insert_user(%{email: "friend1@example.com", username: "friend1"})
      {:ok, _} = Alerts.set_button_friend_alert(button.id, user.id, friend.id, false)

      recipients = Alerts.get_alert_recipients(button.id, user.id)
      assert recipients == []
    end

    test "get_button_alert_preferences/2 returns preferences for button and user", %{user: user, button: button} do
      friend1 = insert_user(%{email: "friend1@example.com", username: "friend1"})
      friend2 = insert_user(%{email: "friend2@example.com", username: "friend2"})

      {:ok, _} = Alerts.set_button_friend_alert(button.id, user.id, friend1.id, true)
      {:ok, _} = Alerts.set_button_friend_alert(button.id, user.id, friend2.id, false)

      prefs = Alerts.get_button_alert_preferences(button.id, user.id)
      assert length(prefs) == 2
    end

    test "get_button_alert_preferences/2 returns empty for different user", %{user: user, button: button} do
      friend = insert_user(%{email: "friend1@example.com", username: "friend1"})
      other_user = insert_user(%{email: "other@example.com", username: "other"})

      {:ok, _} = Alerts.set_button_friend_alert(button.id, user.id, friend.id, true)

      prefs = Alerts.get_button_alert_preferences(button.id, other_user.id)
      assert prefs == []
    end
  end

  describe "friend alert permissions" do
    setup do
      user = insert_user(%{email: "user@example.com", username: "user"})
      friend = insert_user(%{email: "friend@example.com", username: "friend"})
      %{user: user, friend: friend}
    end

    test "get_friend_alert_permissions/2 returns nil when no permissions set", %{user: user, friend: friend} do
      assert Alerts.get_friend_alert_permissions(user.id, friend.id) == nil
    end

    test "upsert_friend_alert_permissions/3 creates new permissions", %{user: user, friend: friend} do
      attrs = %{
        can_receive_button_alerts: true,
        can_receive_friend_requests: true,
        can_receive_general_alerts: true,
        alert_frequency: "immediate"
      }

      assert {:ok, %FriendAlertPermission{} = perm} =
        Alerts.upsert_friend_alert_permissions(attrs, user.id, friend.id)

      assert perm.user_id == user.id
      assert perm.friend_id == friend.id
      assert perm.can_receive_button_alerts == true
      assert perm.alert_frequency == "immediate"
    end

    test "upsert_friend_alert_permissions/3 validates alert_frequency", %{user: user, friend: friend} do
      attrs = %{
        can_receive_button_alerts: true,
        can_receive_friend_requests: true,
        can_receive_general_alerts: true,
        alert_frequency: "invalid_frequency"
      }

      assert {:error, changeset} =
        Alerts.upsert_friend_alert_permissions(attrs, user.id, friend.id)

      assert "is invalid" in errors_on(changeset).alert_frequency
    end

    test "upsert_friend_alert_permissions/3 accepts valid frequencies", %{user: user, friend: friend} do
      valid_frequencies = ["immediate", "hourly", "daily", "weekly"]

      for {frequency, idx} <- Enum.with_index(valid_frequencies) do
        test_friend = insert_user(%{email: "friend#{idx}@example.com", username: "friend#{idx}"})
        attrs = %{
          can_receive_button_alerts: true,
          can_receive_friend_requests: true,
          can_receive_general_alerts: true,
          alert_frequency: frequency
        }

        assert {:ok, perm} = Alerts.upsert_friend_alert_permissions(attrs, user.id, test_friend.id)
        assert perm.alert_frequency == frequency
      end
    end

    test "upsert_friend_alert_permissions/3 updates existing permissions", %{user: user, friend: friend} do
      attrs1 = %{
        can_receive_button_alerts: true,
        can_receive_friend_requests: true,
        can_receive_general_alerts: true,
        alert_frequency: "immediate"
      }
      {:ok, _} = Alerts.upsert_friend_alert_permissions(attrs1, user.id, friend.id)

      attrs2 = %{
        can_receive_button_alerts: false,
        alert_frequency: "daily"
      }
      {:ok, updated} = Alerts.upsert_friend_alert_permissions(attrs2, user.id, friend.id)

      assert updated.can_receive_button_alerts == false
      assert updated.alert_frequency == "daily"
    end

    test "get_friend_alert_permissions/2 returns permissions after creation", %{user: user, friend: friend} do
      attrs = %{
        can_receive_button_alerts: true,
        can_receive_friend_requests: false,
        can_receive_general_alerts: true,
        alert_frequency: "hourly"
      }
      {:ok, _} = Alerts.upsert_friend_alert_permissions(attrs, user.id, friend.id)

      perm = Alerts.get_friend_alert_permissions(user.id, friend.id)
      assert perm.can_receive_button_alerts == true
      assert perm.can_receive_friend_requests == false
      assert perm.alert_frequency == "hourly"
    end
  end

  describe "send_button_click_alerts/3" do
    setup do
      user = insert_user(%{email: "user@example.com", username: "user", display_name: "Test User"})
      friend = insert_user(%{email: "friend@example.com", username: "friend"})
      button = insert_button(user, %{name: "Test Button"})
      %{user: user, friend: friend, button: button}
    end

    test "sends alerts to enabled recipients", %{user: user, friend: friend, button: button} do
      # Enable alerts for friend
      {:ok, _} = Alerts.set_button_friend_alert(button.id, user.id, friend.id, true)

      {:ok, results} = Alerts.send_button_click_alerts(button.id, user.id, %{})

      assert length(results) == 1

      # Check alert was created
      alerts = Alerts.get_user_alerts(friend.id)
      assert length(alerts) == 1
      assert hd(alerts).alert_type == "button_click"
    end

    test "sends no alerts when no recipients enabled", %{user: user, friend: friend, button: button} do
      # Disable alerts for friend
      {:ok, _} = Alerts.set_button_friend_alert(button.id, user.id, friend.id, false)

      {:ok, results} = Alerts.send_button_click_alerts(button.id, user.id, %{})

      assert results == []
    end

    test "returns error for non-existent button", %{user: user} do
      fake_button_id = Ecto.UUID.generate()
      assert {:error, :button_not_found} = Alerts.send_button_click_alerts(fake_button_id, user.id, %{})
    end

    test "uses 'started' verb for start action", %{user: user, friend: friend, button: button} do
      {:ok, _} = Alerts.set_button_friend_alert(button.id, user.id, friend.id, true)

      {:ok, _} = Alerts.send_button_click_alerts(
        button.id,
        user.id,
        %{action: "start", clicked_at: DateTime.utc_now()}
      )

      alerts = Alerts.get_user_alerts(friend.id)
      assert length(alerts) == 1

      alert = hd(alerts)
      assert alert.title =~ "started"
      assert alert.message =~ "started"
    end

    test "uses 'stopped' verb for stop action", %{user: user, friend: friend, button: button} do
      {:ok, _} = Alerts.set_button_friend_alert(button.id, user.id, friend.id, true)

      {:ok, _} = Alerts.send_button_click_alerts(
        button.id,
        user.id,
        %{action: "stop", clicked_at: DateTime.utc_now()}
      )

      alerts = Alerts.get_user_alerts(friend.id)
      assert hd(alerts).title =~ "stopped"
    end

    test "uses 'stopped' verb for end action", %{user: user, friend: friend, button: button} do
      {:ok, _} = Alerts.set_button_friend_alert(button.id, user.id, friend.id, true)

      {:ok, _} = Alerts.send_button_click_alerts(
        button.id,
        user.id,
        %{action: "end", clicked_at: DateTime.utc_now()}
      )

      alerts = Alerts.get_user_alerts(friend.id)
      assert hd(alerts).title =~ "stopped"
    end

    test "uses 'clicked' verb for click action", %{user: user, friend: friend, button: button} do
      {:ok, _} = Alerts.set_button_friend_alert(button.id, user.id, friend.id, true)

      {:ok, _} = Alerts.send_button_click_alerts(
        button.id,
        user.id,
        %{action: "click", clicked_at: DateTime.utc_now()}
      )

      alerts = Alerts.get_user_alerts(friend.id)
      assert hd(alerts).title =~ "clicked"
    end

    test "defaults to 'clicked' verb when no action specified", %{user: user, friend: friend, button: button} do
      {:ok, _} = Alerts.set_button_friend_alert(button.id, user.id, friend.id, true)

      {:ok, _} = Alerts.send_button_click_alerts(button.id, user.id, %{})

      alerts = Alerts.get_user_alerts(friend.id)
      assert hd(alerts).title =~ "clicked"
    end

    test "handles string action keys", %{user: user, friend: friend, button: button} do
      {:ok, _} = Alerts.set_button_friend_alert(button.id, user.id, friend.id, true)

      {:ok, _} = Alerts.send_button_click_alerts(
        button.id,
        user.id,
        %{"action" => "start", "clicked_at" => DateTime.utc_now()}
      )

      alerts = Alerts.get_user_alerts(friend.id)
      assert hd(alerts).title =~ "started"
    end

    test "sends alerts to multiple recipients", %{user: user, button: button} do
      friend1 = insert_user(%{email: "friend1@example.com", username: "friend1"})
      friend2 = insert_user(%{email: "friend2@example.com", username: "friend2"})
      friend3 = insert_user(%{email: "friend3@example.com", username: "friend3"})

      {:ok, _} = Alerts.set_button_friend_alert(button.id, user.id, friend1.id, true)
      {:ok, _} = Alerts.set_button_friend_alert(button.id, user.id, friend2.id, true)
      {:ok, _} = Alerts.set_button_friend_alert(button.id, user.id, friend3.id, false)

      {:ok, results} = Alerts.send_button_click_alerts(button.id, user.id, %{})

      assert length(results) == 2

      assert length(Alerts.get_user_alerts(friend1.id)) == 1
      assert length(Alerts.get_user_alerts(friend2.id)) == 1
      assert length(Alerts.get_user_alerts(friend3.id)) == 0
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

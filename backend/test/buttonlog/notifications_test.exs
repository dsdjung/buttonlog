defmodule ButtonLog.NotificationsTest do
  use ButtonLog.DataCase

  alias ButtonLog.Notifications

  describe "get_action_verbs/1" do
    # Note: get_action_verbs is a private function, so we test it indirectly
    # through the notification message content

    test "notification messages use 'started' for start action" do
      # Create test user, friend, and button
      user = insert_user()
      friend = insert_user(%{email: "friend@test.com", username: "friend"})
      button = insert_button(user, %{name: "Test Timer", button_type: "timed"})

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
      button = insert_button(user, %{name: "Test Timer", button_type: "timed"})

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

    test "notification messages use 'stopped' for end action (timed button stop)" do
      user = insert_user()
      friend = insert_user(%{email: "friend2b@test.com", username: "friend2b"})
      button = insert_button(user, %{name: "Test Timer", button_type: "timed"})

      Notifications.set_button_friend_notification(button.id, user.id, friend.id, true)

      # The buttons context uses "end" action when stopping a timed button
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
      button = insert_button(user, %{name: "Test Timer", button_type: "timed"})

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

  defp insert_button(user, attrs \\ %{}) do
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
